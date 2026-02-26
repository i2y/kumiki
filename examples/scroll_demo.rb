# Kumiki - Scroll Demo
# Run: bundle exec ruby examples/scroll_demo.rb

require "kumiki"
include Kumiki

# Default Tokyo Night theme is auto-initialized

class ScrollDemo < Component
  def initialize
    super
    @count = state(0)
  end

  def view
    col = Column.new.scrollable.spacing(4.0)

    i = 0
    while i < 30
      label = "Item " + i.to_s + " (count: " + @count.value.to_s + ")"
      col.add(
        Row(
          Text(label).font_size(16.0).color(0xFFC0CAF5),
          Spacer(),
          Button(" + ").on_click { @count += 1 }
        ).fixed_height(40.0)
      )
      i = i + 1
    end

    col
  end
end

frame = RanmaFrame.new("Scroll Demo", 400, 600)
app = App.new(frame, ScrollDemo.new)
app.run
