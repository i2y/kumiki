# frozen_string_literal: true

# Kumiki (組木) - Reactive GUI framework for Ruby
#
# A declarative, component-based UI framework powered by SDL3 + Skia.
#
# Usage:
#   require "kumiki"
#   include Kumiki
#
#   class MyApp < Component
#     def initialize
#       super
#       @count = state(0)
#     end
#
#     def view
#       column(padding: 16.0) {
#         text "Count: #{@count}", font_size: 32.0
#         button("Click me") { @count += 1 }
#       }
#     end
#   end
#
#   Kumiki.run("My App", 400, 300) { MyApp.new }

require_relative "kumiki/version"

module Kumiki
  # Theme accessor with lazy initialization (default: Tokyo Night)
  def self.theme
    @theme ||= Theme.new
  end

  def self.theme=(t)
    @theme = t
  end

  # Background clear color propagation (internal use)
  def self._bg_clear_color
    @_bg_clear_color || 0
  end

  def self._bg_clear_color=(v)
    @_bg_clear_color = v
  end

  # When `include Kumiki` is used, also include the DSL
  def self.included(base)
    base.include(Kumiki::DSL)
  end

  # Convenience: run an app
  def self.run(title, width, height, &block)
    widget = block.call
    frame = RanmaFrame.new(title, width, height)
    app = App.new(frame, widget)
    app.run
  end
end

# Core
require_relative "kumiki/render_node"
require_relative "kumiki/core"
require_relative "kumiki/column"
require_relative "kumiki/row"
require_relative "kumiki/box"
require_relative "kumiki/spacer"
require_relative "kumiki/theme"
require_relative "kumiki/themes/tokyo_night"
require_relative "kumiki/themes/material"

# Widgets
require_relative "kumiki/widgets/text"
require_relative "kumiki/widgets/button"
require_relative "kumiki/widgets/divider"
require_relative "kumiki/widgets/container"
require_relative "kumiki/widgets/input"
require_relative "kumiki/widgets/multiline_input"
require_relative "kumiki/widgets/multiline_text"
require_relative "kumiki/widgets/checkbox"
require_relative "kumiki/widgets/radio_buttons"
require_relative "kumiki/widgets/switch"
require_relative "kumiki/widgets/slider"
require_relative "kumiki/widgets/progress_bar"
require_relative "kumiki/widgets/tabs"
require_relative "kumiki/widgets/data_table"
require_relative "kumiki/widgets/tree"
require_relative "kumiki/widgets/calendar"
require_relative "kumiki/widgets/modal"
require_relative "kumiki/widgets/image"
require_relative "kumiki/widgets/net_image"
require_relative "kumiki/widgets/webview"

# Markdown
require_relative "kumiki/markdown/ast"
require_relative "kumiki/markdown/theme"
require_relative "kumiki/markdown/parser"
require_relative "kumiki/markdown/mermaid/models"
require_relative "kumiki/markdown/mermaid/parser"
require_relative "kumiki/markdown/mermaid/layout"
require_relative "kumiki/markdown/mermaid/renderer"
require_relative "kumiki/markdown/renderer"
require_relative "kumiki/widgets/markdown"

# Charts
require_relative "kumiki/chart/chart_helpers"
require_relative "kumiki/chart/scales"
require_relative "kumiki/chart/base_chart"
require_relative "kumiki/chart/bar_chart"
require_relative "kumiki/chart/line_chart"
require_relative "kumiki/chart/pie_chart"
require_relative "kumiki/chart/scatter_chart"
require_relative "kumiki/chart/area_chart"
require_relative "kumiki/chart/stacked_bar_chart"
require_relative "kumiki/chart/gauge_chart"
require_relative "kumiki/chart/heatmap_chart"

# Animation
require_relative "kumiki/animation/easing"
require_relative "kumiki/animation/value_tween"
require_relative "kumiki/animation/animated_state"

# RanmaFrame (ranma GPU) — default frame backend
require_relative "kumiki/frame_ranma"
require_relative "kumiki/app"

# DSL
require_relative "kumiki/style"
require_relative "kumiki/dsl"
