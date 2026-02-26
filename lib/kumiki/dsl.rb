# DSL - Block-based UI tree builder (CSS-inspired)
#
# Uses a widget stack to manage implicit parent-child relationships.
# All DSL functions are methods of the Kumiki::DSL module.
# Include Kumiki (or Kumiki::DSL) to use them.
#
# Usage:
#   include Kumiki
#
#   column(padding: 16.0) {
#     text "Count: #{@count}", font_size: 32.0, color: 0xFFC0CAF5
#     row(spacing: 8.0) {
#       button(" - ", width: 80.0) { @count -= 1 }
#       spacer
#       button(" + ", width: 80.0) { @count += 1 }
#     }
#   }

module Kumiki
  module DSL
    # Widget stack for tracking current parent container
    STACK = []

    private

    def __dsl_push(w)
      STACK.push(w)
    end

    def __dsl_pop
      STACK.pop
    end

    def __dsl_auto_add(w)
      len = STACK.length
      if len > 0
        parent = STACK.last
        if parent != nil
          parent.add(w)
        end
      end
    end

    # Applies keyword arguments directly to a widget.
    def __apply_kwargs(widget, kwargs, typography)
      # Layout
      widget.fixed_width(kwargs[:width]) if kwargs.key?(:width)
      widget.fixed_height(kwargs[:height]) if kwargs.key?(:height)
      if kwargs.key?(:padding)
        p = kwargs[:padding]
        widget.padding(p, p, p, p)
      end
      widget.flex(kwargs[:flex]) if kwargs.key?(:flex)
      widget.fit_content if kwargs[:fit_content]
      # Container
      widget.spacing(kwargs[:spacing]) if kwargs.key?(:spacing)
      widget.scrollable if kwargs[:scrollable]
      widget.pin_to_bottom if kwargs[:pin_to_bottom]
      widget.pin_to_end if kwargs[:pin_to_end]
      # Visual
      widget.bg_color(kwargs[:bg_color]) if kwargs.key?(:bg_color)
      widget.border_color(kwargs[:border_color]) if kwargs.key?(:border_color)
      widget.border_radius(kwargs[:border_radius]) if kwargs.key?(:border_radius)
      # Expanding
      if kwargs[:expanding]
        widget.set_width_policy(Kumiki::EXPANDING)
        widget.set_height_policy(Kumiki::EXPANDING)
      end
      widget.set_width_policy(Kumiki::EXPANDING) if kwargs[:expanding_width]
      widget.set_height_policy(Kumiki::EXPANDING) if kwargs[:expanding_height]
      # Typography (text/button/checkbox etc.)
      if typography
        widget.font_size(kwargs[:font_size]) if kwargs.key?(:font_size)
        widget.color(kwargs[:color]) if kwargs.key?(:color)
        widget.text_color(kwargs[:text_color]) if kwargs.key?(:text_color)
        widget.bold if kwargs[:bold]
        widget.italic if kwargs[:italic]
        widget.font_family(kwargs[:font_family]) if kwargs.key?(:font_family)
        widget.kind(kwargs[:kind]) if kwargs.key?(:kind)
        if kwargs.key?(:align)
          a = kwargs[:align]
          if a == :center
            widget.align(1)
          elsif a == :right
            widget.align(2)
          elsif a == :left
            widget.align(0)
          else
            widget.align(a)
          end
        end
      end
    end

    public

    # --- Style helper ---

    def s
      Kumiki::Style.new
    end

    # --- Container DSL functions ---

    def column(base_style = nil, **kwargs, &block)
      col = Kumiki::Column.new
      if base_style != nil
        base_style.apply(col)
      end
      __apply_kwargs(col, kwargs, false) if kwargs.length > 0
      __dsl_push(col)
      yield
      __dsl_pop
      __dsl_auto_add(col)
      col
    end

    def row(base_style = nil, **kwargs, &block)
      r = Kumiki::Row.new
      if base_style != nil
        base_style.apply(r)
      end
      __apply_kwargs(r, kwargs, false) if kwargs.length > 0
      __dsl_push(r)
      yield
      __dsl_pop
      __dsl_auto_add(r)
      r
    end

    def box(base_style = nil, **kwargs, &block)
      b = Kumiki::Box.new
      if base_style != nil
        base_style.apply(b)
      end
      __apply_kwargs(b, kwargs, false) if kwargs.length > 0
      __dsl_push(b)
      yield
      __dsl_pop
      __dsl_auto_add(b)
      b
    end

    def container(base_style = nil, **kwargs, &block)
      c = Kumiki::Container.new(nil)
      if base_style != nil
        base_style.apply_layout(c)
        base_style.apply_visual(c)
      end
      __apply_kwargs(c, kwargs, false) if kwargs.length > 0
      __dsl_push(c)
      yield
      __dsl_pop
      __dsl_auto_add(c)
      c
    end

    # --- Leaf DSL functions ---

    def text(content, base_style = nil, **kwargs)
      w = Kumiki::Text.new(content)
      if base_style != nil
        base_style.apply(w)
        base_style.apply_typography(w)
      end
      __apply_kwargs(w, kwargs, true) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def button(label, base_style = nil, **kwargs, &block)
      w = Kumiki::Button.new(label)
      if base_style != nil
        base_style.apply(w)
        base_style.apply_typography(w)
      end
      __apply_kwargs(w, kwargs, true) if kwargs.length > 0
      if block_given?
        w.on_click { yield }
      end
      __dsl_auto_add(w)
      w
    end

    def spacer
      w = Kumiki::Spacer.new
      __dsl_auto_add(w)
      w
    end

    def divider
      w = Kumiki::Divider.new
      __dsl_auto_add(w)
      w
    end

    def checkbox(label, base_style = nil, **kwargs)
      w = Kumiki::Checkbox.new(label)
      if base_style != nil
        base_style.apply(w)
        base_style.apply_typography(w)
      end
      __apply_kwargs(w, kwargs, true) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def radio_buttons(options, base_style = nil, **kwargs)
      w = Kumiki::RadioButtons.new(options)
      if base_style != nil
        base_style.apply(w)
      end
      __apply_kwargs(w, kwargs, false) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def slider(min_val, max_val, base_style = nil, **kwargs)
      w = Kumiki::Slider.new(min_val, max_val)
      if base_style != nil
        base_style.apply(w)
      end
      __apply_kwargs(w, kwargs, false) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def image(path, base_style = nil, **kwargs)
      w = Kumiki::ImageWidget.new(path)
      if base_style != nil
        base_style.apply(w)
      end
      __apply_kwargs(w, kwargs, false) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def net_image(url, base_style = nil, **kwargs)
      w = Kumiki::NetImageWidget.new(url)
      if base_style != nil
        base_style.apply(w)
      end
      __apply_kwargs(w, kwargs, false) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def multiline_text(content, base_style = nil, **kwargs)
      w = Kumiki::MultilineText.new(content)
      if base_style != nil
        base_style.apply(w)
        base_style.apply_typography(w)
      end
      __apply_kwargs(w, kwargs, true) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def markdown_text(content, base_style = nil, **kwargs)
      w = Kumiki::Markdown.new(content)
      if base_style != nil
        base_style.apply(w)
      end
      __apply_kwargs(w, kwargs, false) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def text_input(state, base_style = nil, **kwargs)
      w = Kumiki::Input.new(state)
      if base_style != nil
        base_style.apply(w)
        base_style.apply_typography(w)
      end
      __apply_kwargs(w, kwargs, true) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def multiline_input(state, base_style = nil, **kwargs)
      w = Kumiki::MultilineInput.new(state)
      if base_style != nil
        base_style.apply(w)
      end
      __apply_kwargs(w, kwargs, false) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def data_table(cols, widths, rows, base_style = nil, **kwargs)
      w = Kumiki::DataTable.new(cols, widths, rows)
      if base_style != nil
        base_style.apply(w)
        base_style.apply_typography(w)
      end
      __apply_kwargs(w, kwargs, true) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    def switch_toggle
      w = Kumiki::Switch.new
      __dsl_auto_add(w)
      w
    end

    def progress_bar
      w = Kumiki::ProgressBar.new
      __dsl_auto_add(w)
      w
    end

    # --- Complex widget DSL functions ---

    def tabs(labels, contents)
      w = Kumiki::Tabs.new(labels, contents)
      __dsl_auto_add(w)
      w
    end

    def tree(state)
      w = Kumiki::Tree.new(state)
      __dsl_auto_add(w)
      w
    end

    def calendar(state)
      w = Kumiki::Calendar.new(state)
      __dsl_auto_add(w)
      w
    end

    def modal(body)
      w = Kumiki::Modal.new(body)
      __dsl_auto_add(w)
      w
    end

    # --- Chart DSL functions ---

    def bar_chart(labels, data, legends)
      w = Kumiki::BarChart.new(labels, data, legends)
      __dsl_auto_add(w)
      w
    end

    def line_chart(labels, data, legends)
      w = Kumiki::LineChart.new(labels, data, legends)
      __dsl_auto_add(w)
      w
    end

    def pie_chart(labels, values)
      w = Kumiki::PieChart.new(labels, values)
      __dsl_auto_add(w)
      w
    end

    def scatter_chart(x_data, y_data, legends)
      w = Kumiki::ScatterChart.new(x_data, y_data, legends)
      __dsl_auto_add(w)
      w
    end

    def area_chart(labels, data, legends)
      w = Kumiki::AreaChart.new(labels, data, legends)
      __dsl_auto_add(w)
      w
    end

    def stacked_bar_chart(labels, data, legends)
      w = Kumiki::StackedBarChart.new(labels, data, legends)
      __dsl_auto_add(w)
      w
    end

    def gauge_chart(value, min_val, max_val)
      w = Kumiki::GaugeChart.new(value, min_val, max_val)
      __dsl_auto_add(w)
      w
    end

    def heatmap_chart(x_labels, y_labels, data)
      w = Kumiki::HeatmapChart.new(x_labels, y_labels, data)
      __dsl_auto_add(w)
      w
    end

    def webview(url: nil, html: nil, **kwargs)
      w = Kumiki::WebViewWidget.new(url: url, html: html)
      __apply_kwargs(w, kwargs, false) if kwargs.length > 0
      __dsl_auto_add(w)
      w
    end

    # --- Generic embed function ---

    def embed(w)
      __dsl_auto_add(w)
      w
    end
  end

  # Auto-include DSL in Component so view() methods can use DSL functions
  class Component
    include Kumiki::DSL
  end
end
