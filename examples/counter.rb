# Kumiki - Counter Demo
#
# Same as framework_counter.rb but uses RanmaFrame.
# Run: bundle exec ruby examples/counter.rb

require "kumiki"
include Kumiki

# Global theme
# Default Tokyo Night theme is auto-initialized

# ===== Counter Component =====
class CounterComponent < Component
  def initialize
    super
    @count = state(0)
  end

  def view
    label = "Count: " + @count.value.to_s

    Column(
      Text(label).font_size(32).color(0xFFC0CAF5).align(TEXT_ALIGN_CENTER),
      Row(
        Button("  -  ").font_size(24).on_click {
          @count -= 1
        },
        Button("  +  ").font_size(24).on_click {
          @count += 1
        }
      )
    )
  end
end

# ===== Launch =====
frame = RanmaFrame.new("Kumiki Counter", 400, 300)
app = App.new(frame, CounterComponent.new)
app.run
