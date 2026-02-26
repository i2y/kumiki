# frozen_string_literal: true

module Kumiki
  class WebViewWidget < Widget
    def initialize(url: nil, html: nil)
      super()
      @initial_url  = url
      @initial_html = html
      @webview      = nil
      @last_bounds  = nil
      @ipc_handler  = nil
      @nav_handler  = nil
      set_width_policy(EXPANDING)
      set_height_policy(EXPANDING)
    end

    def load_url(url)
      @webview ? @webview.load_url(url) : (@initial_url = url; @initial_html = nil)
      self
    end

    def load_html(html)
      @webview ? @webview.load_html(html) : (@initial_html = html; @initial_url = nil)
      self
    end

    def evaluate_script(js)  = (@webview&.evaluate_script(js); self)
    def reload               = (@webview&.reload; self)
    def zoom(factor)         = (@webview&.zoom(factor.to_f); self)

    def on_ipc_message(&block)
      @ipc_handler = block
      @webview&.on_ipc_message(&block)
      self
    end

    def on_navigation(&block)
      @nav_handler = block
      @webview&.on_navigation(&block)
      self
    end

    # Native WebView handles its own OS-level events; kumiki doesn't dispatch into it
    def dispatch(_pos) = [nil, nil]

    # Called by Tabs when this widget's tab becomes hidden/shown
    def on_tab_hide = @webview&.set_visible(false)
    def on_tab_show = (@last_bounds = nil; @webview&.set_visible(true))

    def redraw(_painter, _completely)
      _ensure_created
      _sync_bounds
    end

    def measure(_painter) = Size.new(400.0, 300.0)

    private

    def _ensure_created
      return if @webview
      frame  = App.current&.instance_variable_get(:@frame)
      window = frame&.window
      return unless window

      opts = {}
      opts[:url]  = @initial_url  if @initial_url
      opts[:html] = @initial_html if @initial_html && !@initial_url
      @webview = Ranma::WebView.new(window, **opts)
      @webview.on_ipc_message(&@ipc_handler) if @ipc_handler
      @webview.on_navigation(&@nav_handler)  if @nav_handler
      @webview.set_visible(true)
    end

    def _sync_bounds
      return unless @webview
      bounds = [get_x.to_i, get_y.to_i, get_width.to_i, get_height.to_i]
      if bounds != @last_bounds
        @last_bounds = bounds
        @webview.set_bounds(*bounds)
      end
    end
  end

  def WebView(url: nil, html: nil)
    WebViewWidget.new(url: url, html: html)
  end
end
