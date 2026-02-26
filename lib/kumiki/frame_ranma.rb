# frozen_string_literal: true

# RanmaFrame + RanmaPainter — window and rendering backend for kumiki
#
# Separates Frame (window/events) from Painter (drawing).
# RanmaFrame#_do_redraw passes the RanmaPainter instance to the on_redraw callback.
#
# Usage:
#   require "kumiki/frame_ranma"
#   frame = Kumiki::RanmaFrame.new("My App", 800, 600)
#   app = Kumiki::App.new(frame, widget)
#   app.run

begin
  require "ranma"
rescue LoadError => e
  raise LoadError, "kumiki/frame_ranma requires the 'ranma' gem: #{e.message}"
end

module Kumiki
  # Key ordinals used by kumiki widgets (via RANMA_KEY_MAP)
  # ENTER=11, BACKSPACE=12, TAB=13, ESCAPE=17, END=21, HOME=22
  # LEFT=23, UP=24, RIGHT=25, DOWN=26, DELETE=75
  # A=43, C=45, V=64, X=66
  RANMA_KEY_MAP = {
    enter: 11, backspace: 12, tab: 13, escape: 17,
    end: 21, home: 22, left: 23, up: 24, right: 25, down: 26,
    delete: 75, a: 43, c: 45, v: 64, x: 66,
  }.freeze

  # ─── Net image download cache (shared across all RanmaPainter instances) ───
  require 'tmpdir'
  NET_IMG_CACHE   = {}
  NET_IMG_MUTEX   = Mutex.new
  NET_IMG_DIR     = File.join(Dir.tmpdir, "kumiki_net_#{Process.pid}")
  NET_IMG_HAS_NEW = [false]   # set true by download thread; cleared in _do_redraw

  # ─── Painter ──────────────────────────────────────────────────────────────
  # Wraps Ranma::Painter and implements kumiki's painter protocol.

  class RanmaPainter
    def initialize(surface)
      @inner = Ranma::Painter.new(surface)
      # image cache: path -> integer ID
      @image_store = {}
      @image_path_to_id = {}
      @next_image_id = 1
      # font metrics cache: "family_size" -> RbPainterFontMetrics
      @metrics_cache = {}
    end

    # --- Canvas state ---

    def save    = @inner.save
    def restore = @inner.restore
    def translate(dx, dy) = @inner.translate(dx.to_f, dy.to_f)
    def scale(sx, sy)     = @inner.scale(sx.to_f, sy.to_f)
    def clip_rect(x, y, w, h) = @inner.clip(x.to_f, y.to_f, w.to_f, h.to_f)

    def flush = @inner.flush

    # --- Drawing primitives (colors are 0xAARRGGBB integers) ---

    def clear(color)
      @inner.clear_all(int_to_hex(color))
    end

    def fill_rect(x, y, w, h, color)
      @inner.style(Ranma::PainterStyle.new(fill_color: int_to_hex(color)))
      @inner.fill_rect(x.to_f, y.to_f, w.to_f, h.to_f)
    end

    def stroke_rect(x, y, w, h, color, sw)
      @inner.style(Ranma::PainterStyle.new(stroke_color: int_to_hex(color), stroke_width: sw.to_f))
      @inner.stroke_rect(x.to_f, y.to_f, w.to_f, h.to_f)
    end

    def fill_round_rect(x, y, w, h, r, color)
      @inner.style(Ranma::PainterStyle.new(fill_color: int_to_hex(color), border_radius: r.to_f))
      @inner.fill_rect(x.to_f, y.to_f, w.to_f, h.to_f)
    end

    def stroke_round_rect(x, y, w, h, r, color, sw)
      @inner.style(Ranma::PainterStyle.new(
        stroke_color: int_to_hex(color), stroke_width: sw.to_f, border_radius: r.to_f
      ))
      @inner.stroke_rect(x.to_f, y.to_f, w.to_f, h.to_f)
    end

    def fill_circle(cx, cy, r, color)
      @inner.style(Ranma::PainterStyle.new(fill_color: int_to_hex(color)))
      @inner.fill_circle(cx.to_f, cy.to_f, r.to_f)
    end

    def stroke_circle(cx, cy, r, color, sw)
      @inner.style(Ranma::PainterStyle.new(stroke_color: int_to_hex(color), stroke_width: sw.to_f))
      @inner.stroke_circle(cx.to_f, cy.to_f, r.to_f)
    end

    def draw_line(x1, y1, x2, y2, color, w)
      @inner.style(Ranma::PainterStyle.new(stroke_color: int_to_hex(color), stroke_width: w.to_f))
      @inner.draw_line(x1.to_f, y1.to_f, x2.to_f, y2.to_f)
    end

    def fill_arc(cx, cy, r, start_angle, sweep_angle, color)
      @inner.style(Ranma::PainterStyle.new(fill_color: int_to_hex(color)))
      @inner.fill_arc(cx.to_f, cy.to_f, r.to_f, start_angle.to_f, sweep_angle.to_f)
    end

    def stroke_arc(cx, cy, r, start_angle, sweep_angle, color, sw)
      @inner.style(Ranma::PainterStyle.new(stroke_color: int_to_hex(color), stroke_width: sw.to_f))
      @inner.stroke_arc(cx.to_f, cy.to_f, r.to_f, start_angle.to_f, sweep_angle.to_f)
    end

    def draw_polyline(x1, y1, x2, y2, color, sw, _dummy)
      draw_line(x1, y1, x2, y2, color, sw)
    end

    def fill_triangle(x1, y1, x2, y2, x3, y3, color)
      @inner.style(Ranma::PainterStyle.new(fill_color: int_to_hex(color)))
      @inner.fill_triangle(x1.to_f, y1.to_f, x2.to_f, y2.to_f, x3.to_f, y3.to_f)
    end

    # --- Text drawing ---
    # y is the baseline position (Skia convention). ranma uses top, so subtract ascent.

    def draw_text(text, x, y, font_family, font_size, color, *_extra)
      opts = { fill_color: int_to_hex(color), font_size: font_size.to_f }
      f = ranma_font(font_family)
      opts[:font_family] = f if f
      @inner.style(Ranma::PainterStyle.new(**opts))
      top_y = y.to_f - get_ascent(font_family, font_size)
      @inner.fill_text(text.to_s, x.to_f, top_y, nil)
    end

    # --- Text measurement ---

    def measure_text_width(text, font_family, font_size)
      @inner.measure_text_with_font(text.to_s, ranma_font(font_family) || "", font_size.to_f)
    end

    def measure_text_height(font_family, font_size)
      cached_metrics(font_family, font_size).height
    end

    def get_text_ascent(font_family, font_size)
      get_ascent(font_family, font_size)
    end

    # --- Path operations ---

    def begin_path               = @inner.begin_path
    def path_move_to(x, y)       = @inner.path_move_to(x.to_f, y.to_f)
    def path_line_to(x, y)       = @inner.path_line_to(x.to_f, y.to_f)

    def close_fill_path(color)
      @inner.style(Ranma::PainterStyle.new(fill_color: int_to_hex(color)))
      @inner.close_fill_path
    end

    def fill_path(color)
      @inner.style(Ranma::PainterStyle.new(fill_color: int_to_hex(color)))
      @inner.fill_path
    end

    # --- Image operations ---

    def load_image(path)
      return @image_path_to_id[path] if @image_path_to_id.key?(path)
      id = @next_image_id
      @next_image_id += 1
      @image_store[id] = path
      @image_path_to_id[path] = id
      id
    end

    def load_net_image(url)
      return @image_path_to_id[url] if @image_path_to_id.key?(url)

      status = NET_IMG_MUTEX.synchronize { NET_IMG_CACHE[url] }
      case status
      when String  # download complete — register with painter
        id = @next_image_id; @next_image_id += 1
        @image_store[id] = status; @image_path_to_id[url] = id
        return id
      when :pending, :failed
        return 0
      end

      # First request: kick off background download
      NET_IMG_MUTEX.synchronize { NET_IMG_CACHE[url] = :pending }
      painter = self
      Thread.new do
        begin
          painter.send(:_download_net_image, url)
        rescue Exception => e
          $stderr.puts "NetImage thread error: #{e.class}: #{e}"
          NET_IMG_MUTEX.synchronize { NET_IMG_CACHE[url] = :failed }
        end
      end
      0
    rescue => e
      $stderr.puts "NetImage load error: #{e}"
      0
    end

    def draw_image(image_id, x, y, w, h)
      path = @image_store[image_id]
      return unless path
      begin
        @inner.draw_image(path, x.to_f, y.to_f, w.to_f, h.to_f)
      rescue; end
    end

    def get_image_width(image_id)
      path = @image_store[image_id]
      return 0 unless path
      begin; @inner.measure_image(path)[0]; rescue; 0; end
    end

    def get_image_height(image_id)
      path = @image_store[image_id]
      return 0 unless path
      begin; @inner.measure_image(path)[1]; rescue; 0; end
    end

    # --- Color utilities (0xAARRGGBB) ---

    def interpolate_color(c1, c2, t)
      a1, r1, g1, b1 = int_to_argb(c1)
      a2, r2, g2, b2 = int_to_argb(c2)
      argb_to_int(
        lerp(a1, a2, t), lerp(r1, r2, t), lerp(g1, g2, t), lerp(b1, b2, t)
      )
    end

    def with_alpha(color, alpha)
      _a, r, g, b = int_to_argb(color)
      argb_to_int((alpha * 255).to_i.clamp(0, 255), r, g, b)
    end

    def lighten_color(color, amount)
      a, r, g, b = int_to_argb(color)
      amt = (amount * 255).to_i
      argb_to_int(a, (r + amt).clamp(0, 255), (g + amt).clamp(0, 255), (b + amt).clamp(0, 255))
    end

    def darken_color(color, amount)
      a, r, g, b = int_to_argb(color)
      amt = (amount * 255).to_i
      argb_to_int(a, (r - amt).clamp(0, 255), (g - amt).clamp(0, 255), (b - amt).clamp(0, 255))
    end

    # --- Math / time (called on painter by kumiki App) ---

    def math_cos(r)    = Math.cos(r)
    def math_sin(r)    = Math.sin(r)
    def math_sqrt(v)   = Math.sqrt(v)
    def math_atan2(y, x) = Math.atan2(y, x)
    def math_abs(v)    = v.abs

    def current_time_millis
      (Process.clock_gettime(Process::CLOCK_MONOTONIC) * 1000).to_i
    end

    def number_to_string(v) = v.to_s

    # --- Sub-painter support (vello scene caching) ---

    def supports_sub_painter? = true

    def create_sub_painter
      sub = RanmaPainter.allocate
      sub.instance_variable_set(:@inner, @inner.create_sub_painter)
      sub.instance_variable_set(:@image_store, @image_store)
      sub.instance_variable_set(:@image_path_to_id, @image_path_to_id)
      sub.instance_variable_set(:@next_image_id, @next_image_id)
      sub.instance_variable_set(:@metrics_cache, @metrics_cache)
      sub
    end

    def append(sub_painter, x = 0.0, y = 0.0)
      @inner.append(sub_painter.instance_variable_get(:@inner), x.to_f, y.to_f)
    end

    def reset
      @inner.reset
    end

    private

    def ranma_font(family)
      return nil if family.nil? || family.empty? || family == "default"
      family
    end

    def get_ascent(font_family, font_size)
      cached_metrics(font_family, font_size).ascent
    end

    def cached_metrics(font_family, font_size)
      key = "#{font_family}_#{font_size}"
      @metrics_cache[key] ||= @inner.get_font_metrics_with_font(
        ranma_font(font_family) || "", font_size.to_f
      )
    end

    # 0xAARRGGBB -> "#rrggbbaa"
    def int_to_hex(color)
      a = (color >> 24) & 0xFF
      r = (color >> 16) & 0xFF
      g = (color >> 8)  & 0xFF
      b =  color        & 0xFF
      "#%02x%02x%02x%02x" % [r, g, b, a]
    end

    def int_to_argb(color)
      [(color >> 24) & 0xFF, (color >> 16) & 0xFF, (color >> 8) & 0xFF, color & 0xFF]
    end

    def argb_to_int(a, r, g, b)
      ((a & 0xFF) << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF)
    end

    def lerp(a, b, t)
      (a + (b - a) * t).to_i.clamp(0, 255)
    end

    def _download_net_image(url)
      require 'open-uri'; require 'fileutils'; require 'digest'; require 'uri'
      FileUtils.mkdir_p(NET_IMG_DIR)
      ext  = File.extname(URI.parse(url).path).then { |e| e.empty? ? ".jpg" : e }
      path = File.join(NET_IMG_DIR, "#{Digest::MD5.hexdigest(url)}#{ext}")
      unless File.exist?(path)
        URI.open(url, "rb") { |f| File.binwrite(path, f.read) }
      end
      NET_IMG_MUTEX.synchronize { NET_IMG_CACHE[url] = path; NET_IMG_HAS_NEW[0] = true }
      Ranma::App.request_redraw
    rescue => e
      $stderr.puts "NetImage download failed for #{url}: #{e}"
      NET_IMG_MUTEX.synchronize { NET_IMG_CACHE[url] = :failed }
    end
  end

  # ─── Frame ────────────────────────────────────────────────────────────────
  # Creates the window via Ranma::App.start and translates events into kumiki callbacks.
  # Passes a RanmaPainter instance (not self) to the on_redraw callback.

  class RanmaFrame
    def initialize(title, width, height)
      @title  = title
      @width  = width.to_i
      @height = height.to_i

      # event callbacks
      @on_redraw     = nil
      @on_mouse_down = nil
      @on_mouse_up   = nil
      @on_cursor_pos = nil
      @on_mouse_wheel = nil
      @on_input_char = nil
      @on_input_key  = nil
      @on_resize     = nil
      @on_ime_preedit = nil

      # runtime state
      @window      = nil
      @surface     = nil
      @ranma_painter = nil   # created in _update_painter
      @hidpi_scale = 1.0
      @size = Size.new(width.to_f, height.to_f)

      @last_cursor_x = 0.0
      @last_cursor_y = 0.0
      @mods = 0  # modifier bitmask
      @in_redraw = false
      @skip_redraw_requested = false
      @animation_pending = false
    end

    attr_reader :window

    # --- Callback registration ---

    def on_redraw(&block)      = (@on_redraw = block)
    def on_mouse_down(&block)  = (@on_mouse_down = block)
    def on_mouse_up(&block)    = (@on_mouse_up = block)
    def on_cursor_pos(&block)  = (@on_cursor_pos = block)
    def on_mouse_wheel(&block) = (@on_mouse_wheel = block)
    def on_input_char(&block)  = (@on_input_char = block)
    def on_input_key(&block)   = (@on_input_key = block)
    def on_resize(&block)      = (@on_resize = block)
    def on_ime_preedit(&block) = (@on_ime_preedit = block)

    # --- Frame queries ---

    def get_painter = @ranma_painter
    def get_size    = @size

    def is_dark_mode
      Ranma::Theme.detect == :dark
    end

    def post_update(_ev)
      if @in_redraw
        # Called from within on_redraw (e.g. animation tick) — schedule next frame.
        # Set flag so :redraw_requested handler knows NOT to skip (animation is pending).
        @animation_pending = true
        @window&.request_redraw
      else
        # Called from event handler — render immediately for responsiveness
        _do_redraw(false)
      end
    end

    # --- IME / text input ---

    def enable_text_input  = nil   # IME always active
    def disable_text_input = nil

    def set_ime_cursor_rect(x, y, _w, _h)
      return unless @window
      begin
        @window.set_ime_position(Ranma::LogicalPosition.new(x.to_f, y.to_f))
      rescue; end
    end

    # --- Clipboard ---

    def get_clipboard_text
      Ranma::Clipboard.get_text
    rescue
      ""
    end

    def set_clipboard_text(text)
      Ranma::Clipboard.set_text(text)
    rescue
      nil
    end

    # --- Main run ---

    def run
      Ranma::App.start do
        @window = Ranma::AppWindow.new(
          title: @title,
          inner_size: Ranma::LogicalSize.new(@width, @height)
        )

        @hidpi_scale = begin
          @window.scale_factor
        rescue
          1.0
        end

        @surface = Ranma::GpuSurface.new(@window)
        _update_painter   # create initial RanmaPainter

        phys_w = @surface.width
        phys_h = @surface.height
        @size = Size.new(phys_w.to_f / @hidpi_scale, phys_h.to_f / @hidpi_scale)

        @window.setup_ime_preedit
        @window.on_event { |event| _handle_event(event) }
        @window.visible = true
        # No request_redraw here: set_visible triggers :resized which renders
        # synchronously, and the OS fires :redraw_requested right after (consumed by skip).
        # An explicit request_redraw would create an extra :redraw_requested that could
        # interfere with the skip timing and consume the animation loop's first frame.
      end
    end

    private

    def _update_painter
      @ranma_painter = RanmaPainter.new(@surface)
    end

    def _handle_event(event)
      case event[:type]
      when :close_requested
        Ranma::App.exit

      when :resized
        phys_w = event[:width]
        phys_h = event[:height]
        @surface.resize(phys_w, phys_h)
        @size = Size.new(phys_w.to_f / @hidpi_scale, phys_h.to_f / @hidpi_scale)
        @on_resize&.call
        _do_redraw(true)
        @skip_redraw_requested = true  # consume the OS-fired :redraw_requested that follows

      when :scale_factor_changed
        @hidpi_scale = event[:scale_factor].to_f
        nw = event[:new_width]  || (@width  * @hidpi_scale).to_i
        nh = event[:new_height] || (@height * @hidpi_scale).to_i
        @surface.resize(nw, nh)
        @size = Size.new(nw.to_f / @hidpi_scale, nh.to_f / @hidpi_scale)
        _do_redraw(true)
        @skip_redraw_requested = true

      when :redraw_requested
        skip = @skip_redraw_requested && !@animation_pending
        @skip_redraw_requested = false
        @animation_pending = false
        _do_redraw(false) unless skip

      when :modifiers_changed
        @mods = 0
        @mods |= 0x0001 if event[:shift]
        @mods |= 0x0002 if event[:ctrl]
        @mods |= 0x0004 if event[:alt]
        @mods |= 0x0008 if event[:logo]

      when :cursor_moved
        x = event[:x].to_f / @hidpi_scale
        y = event[:y].to_f / @hidpi_scale
        @last_cursor_x = x
        @last_cursor_y = y
        @on_cursor_pos&.call(MouseEvent.new(Point.new(x, y), 0))

      when :mouse_input
        pos = Point.new(@last_cursor_x, @last_cursor_y)
        if event[:state] == :pressed && event[:button] == :left
          @on_mouse_down&.call(MouseEvent.new(pos, 0))
        elsif event[:state] == :released && event[:button] == :left
          @on_mouse_up&.call(MouseEvent.new(pos, 0))
        end

      when :mouse_wheel
        pos = Point.new(@last_cursor_x, @last_cursor_y)
        delta_y = event[:delta_y].to_f
        @on_mouse_wheel&.call(WheelEvent.new(pos, -delta_y * 20.0))

      when :keyboard_input
        if event[:state] == :pressed
          key_code = RANMA_KEY_MAP[event[:key_code]] || 0
          @on_input_key&.call(key_code, @mods) if key_code != 0
        end

      when :received_ime_text
        event[:text]&.each_char { |ch| @on_input_char&.call(ch) }

      when :ime_preedit
        cursor_pos = event[:cursor_pos] || 0
        @on_ime_preedit&.call(event[:text], cursor_pos, cursor_pos)
      end
    end

    # Renders the frame: clear -> save/scale -> callback -> restore -> flush
    def _do_redraw(force_full)
      return unless @ranma_painter && @on_redraw
      # If a net-image download finished since last redraw, force a full repaint
      # so the sub-painter cache is bypassed and the image appears immediately.
      has_new = NET_IMG_MUTEX.synchronize { v = NET_IMG_HAS_NEW[0]; NET_IMG_HAS_NEW[0] = false; v }
      force_full = true if has_new

      @in_redraw = true
      @ranma_painter.clear(Kumiki.theme.bg_canvas)
      @ranma_painter.save
      @ranma_painter.scale(@hidpi_scale, @hidpi_scale) if @hidpi_scale != 1.0
      @on_redraw.call(@ranma_painter, force_full)
      @ranma_painter.restore
      @ranma_painter.flush
    ensure
      @in_redraw = false
    end
  end
end
