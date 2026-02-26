# Kumiki

**A declarative, reactive GUI framework for Ruby**

[![Ruby](https://img.shields.io/badge/ruby-%3E%3D%203.1-CC342D?logo=ruby)](https://www.ruby-lang.org/)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

Kumiki (組木) is a component-based desktop GUI framework for Ruby, based on a Ruby port of [castella](https://github.com/i2y/castella). Define your UI declaratively with a clean block-based DSL; the reactive state system handles updates automatically. Rendering is powered by [ranma](https://github.com/i2y/ranma) (tao + Vello GPU).

---

## Features

- **Reactive state** — `State` objects trigger automatic UI rebuilds on change
- **Block-based DSL** — `column`, `row`, `text`, `button`, ... with keyword-arg styling
- **GPU rendering** — hardware-accelerated via ranma (tao + Vello)
- **Rich widget set** — 20+ widgets covering inputs, layout, data display, and more
- **Animation** — `AnimatedState` with built-in easing functions
- **Theming** — Tokyo Night (default) and Material Design themes included
- **Charts** — 8 chart types: Bar, Line, Pie, Scatter, Area, StackedBar, Gauge, Heatmap
- **Markdown** — Markdown rendering with Mermaid diagram support
- **WebView** — embedded browser widget

---

## Installation

Add to your `Gemfile`:

```ruby
gem "kumiki"
```

Or install directly:

```sh
gem install kumiki
```

---

## Quick Start

```ruby
require "kumiki"
include Kumiki

class Counter < Component
  def initialize
    super
    @count = state(0)
  end

  def view
    column(padding: 16.0, spacing: 8.0) {
      text "Count: #{@count}", font_size: 32.0, align: :center
      row(spacing: 8.0) {
        button(" - ") { @count -= 1 }
        button(" + ") { @count += 1 }
      }
    }
  end
end

Kumiki.run("Counter", 400, 300) { Counter.new }
```

---

## Widget Reference

### Layouts

| Widget | Description |
|--------|-------------|
| `Column` / `column` | Vertical stack |
| `Row` / `row` | Horizontal stack |
| `Box` / `box` | Z-stack overlay |

### Container

| Widget | Description |
|--------|-------------|
| `Container` / `container` | Background, border, border-radius, scrollable |

### Leaf Widgets

| Widget | Description |
|--------|-------------|
| `Text` / `text` | Static or dynamic text |
| `Button` / `button` | Clickable button with `kind:` variants |
| `Input` / `input` | Single-line text input |
| `MultilineInput` / `multiline_input` | Multi-line text input |
| `MultilineText` / `multiline_text` | Read-only multi-line text |
| `Checkbox` / `checkbox` | Boolean toggle |
| `RadioButtons` / `radio_buttons` | Single selection from options |
| `Switch` / `switch` | Toggle switch |
| `Slider` / `slider` | Value slider with range |
| `ProgressBar` / `progress_bar` | Progress indicator |
| `Divider` / `divider` | Horizontal rule |
| `Spacer` / `spacer` | Flexible space |
| `ImageWidget` / `image` | Local image |
| `NetImageWidget` / `net_image` | Async remote image |
| `WebViewWidget` / `webview` | Embedded web browser |

### Complex Widgets

| Widget | Description |
|--------|-------------|
| `Tabs` / `tabs` | Tabbed panels |
| `Tree` / `tree` | Collapsible tree navigation |
| `Calendar` / `calendar` | Month calendar with selection |
| `Modal` / `modal` | Overlay dialog |
| `DataTable` / `data_table` | Sortable, scrollable table |

### Charts

| Widget | Description |
|--------|-------------|
| `BarChart` | Vertical bar chart |
| `LineChart` | Line / time-series chart |
| `PieChart` | Pie chart |
| `ScatterChart` | Scatter plot |
| `AreaChart` | Area chart |
| `StackedBarChart` | Stacked bar chart |
| `GaugeChart` | Circular gauge |
| `HeatmapChart` | 2D heatmap |

### Markdown

| Widget | Description |
|--------|-------------|
| `Markdown` / `markdown_text` | Renders Markdown with Mermaid diagram support |

---

## DSL Style vs Object Style

Both styles can be mixed freely. The DSL is preferred for new code.

**DSL (block-based):**

```ruby
column(padding: 16.0, spacing: 8.0) {
  text "Hello", font_size: 24.0
  button("Click me") { puts "clicked" }
}
```

**Object-based:**

```ruby
Column(
  Text("Hello").font_size(24.0),
  Button("Click me") { puts "clicked" }
).padding(16.0).spacing(8.0)
```

---

## Animation

```ruby
class MyApp < Component
  def initialize
    super
    # AnimatedState.new(initial_value, duration_ms, easing)
    @x = AnimatedState.new(0.0, 400.0, :ease_out)
    @x.attach(self)
  end

  def view
    column {
      box {
        container(x: @x.value, width: 60.0, height: 60.0, background: 0xFF7AA2F7)
      }
      button("Animate") { @x.set(200.0) }
    }
  end
end
```

Available easing functions: `:linear`, `:ease_in`, `:ease_out`, `:ease_in_out`, `:ease_in_cubic`, `:ease_out_cubic`, `:ease_in_out_cubic`, `:bounce`

---

## Theming

```ruby
require "kumiki"

# Default: Tokyo Night
Kumiki.run("App", 800, 600) { MyApp.new }

# Material Design (light)
Kumiki.theme = Kumiki.material_theme
Kumiki.run("App", 800, 600) { MyApp.new }
```

Widget `kind:` prop applies semantic colors from the active theme:

```ruby
button("OK",     kind: :success)
button("Cancel", kind: :danger)
button("Info",   kind: :info)
button("Warn",   kind: :warning)
```

---

## Examples

The `examples/` directory contains runnable demos:

| File | Description |
|------|-------------|
| `dsl_counter_demo.rb` | Minimal counter — reactive state + DSL |
| `counter.rb` | Counter using object-based style |
| `all_widgets_demo.rb` | Comprehensive showcase of every widget |
| `animation_demo.rb` | Animation system with various easing functions |
| `chart_demo.rb` | All 8 chart types |
| `data_table_demo.rb` | Sortable DataTable |
| `calendar_demo.rb` | Calendar widget |
| `tree_demo.rb` | Tree navigation |
| `tabs_demo.rb` | Tabbed interface |
| `modal_demo.rb` | Modal dialogs |
| `markdown_demo.rb` | Markdown + Mermaid rendering |
| `input_demo.rb` | Input fields and text widgets |
| `scroll_demo.rb` | Scrollable containers |
| `focus_demo.rb` | Keyboard focus and Tab cycling |
| `theme_demo.rb` | Theme presets and `kind:` variants |
| `theme_mode_demo.rb` | Light / dark mode switching |
| `dsl_style_demo.rb` | DSL styling examples |
| `dsl_calc.rb` | Calculator app |
| `widgets_demo.rb` | Basic widgets overview |

Run any example:

```sh
bundle install
bundle exec ruby examples/dsl_counter_demo.rb
```

---

## Requirements

- Ruby >= 3.1.0
- macOS or Linux
- The `ranma` gem is installed automatically as a dependency

---

## License

MIT — Copyright (c) 2026 Yasushi Itoh. See [LICENSE](LICENSE) for details.
