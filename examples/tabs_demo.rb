# Kumiki - Tabs Demo
#
# Same as tabs_demo.rb but uses RanmaFrame.
# Run: bundle exec ruby examples/tabs_demo.rb

require "kumiki"
include Kumiki

# Global theme
# Default Tokyo Night theme is auto-initialized

class TabsDemo < Component
  def initialize
    super
  end

  def view
    # Tab 1: Home
    home_tab = Column(
      Text("Welcome Home").font_size(18.0).color(0xFFC0CAF5),
      Spacer().fixed_height(8.0),
      Text("This is the home tab content.").font_size(14.0).color(0xFF9AA5CE),
      Spacer().fixed_height(8.0),
      Text("Click the tabs above to switch pages.").font_size(13.0).color(0xFF565F89)
    ).spacing(4.0)

    # Tab 2: Settings
    settings_tab = Column(
      Text("Settings").font_size(18.0).color(0xFFC0CAF5),
      Spacer().fixed_height(8.0),
      Text("Name:").font_size(14.0).color(0xFF9AA5CE),
      Input("Enter name"),
      Spacer().fixed_height(4.0),
      Text("Email:").font_size(14.0).color(0xFF9AA5CE),
      Input("Enter email"),
      Spacer().fixed_height(8.0),
      Checkbox("Enable notifications")
    ).spacing(4.0)

    # Tab 3: About
    about_tab = Column(
      Text("About").font_size(18.0).color(0xFFC0CAF5),
      Spacer().fixed_height(8.0),
      Text("Kumiki").font_size(14.0).color(0xFF9AA5CE),
      Text("A cross-platform UI framework").font_size(13.0).color(0xFF565F89),
      Spacer().fixed_height(8.0),
      Text("Built with ranma + Vello GPU").font_size(13.0).color(0xFF565F89)
    ).spacing(4.0)

    labels = ["Home", "Settings", "About"]
    contents = [home_tab, settings_tab, about_tab]

    Column(
      Tabs(labels, contents)
    )
  end
end

frame = RanmaFrame.new("Tabs Demo", 500, 400)
app = App.new(frame, TabsDemo.new)
app.run
