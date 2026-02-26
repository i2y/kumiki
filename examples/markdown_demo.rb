# Kumiki - Markdown Demo
#
# Same as markdown_demo.rb but uses RanmaFrame.
# Demonstrates the Markdown widget.
# Run: bundle exec ruby examples/markdown_demo.rb

require "kumiki"
include Kumiki

# Global theme
# Default Tokyo Night theme is auto-initialized

SAMPLE_MARKDOWN = "# Markdown Demo\n\nThis is a **Kumiki** markdown widget.\n\n## Text Formatting\n\nYou can use **bold text** and *italic text*.\n\n## Code Block\n\n```ruby\nputs 42\n```\n\n## Lists\n\n- First item\n- Second item\n\n## Mermaid Flowchart\n\n```mermaid\ngraph TD\n    A[Start] --> B{Is it working?}\n    B -->|Yes| C[Great!]\n    B -->|No| D[Debug]\n    D --> B\n    C --> E[Done]\n```\n\n## Horizontal Flowchart\n\n```mermaid\ngraph LR\n    Input[User Input] --> Parse(Parse Request)\n    Parse --> Validate{Valid?}\n    Validate -->|Yes| Process[Process Data]\n    Validate -->|No| Error[Show Error]\n    Process --> Output[Return Result]\n```\n\nDone!"

class MarkdownDemo < Component
  def view
    Column(
      Markdown(SAMPLE_MARKDOWN)
    ).scrollable
  end
end

frame = RanmaFrame.new("Markdown Demo", 700, 800)
app = App.new(frame, MarkdownDemo.new)
app.run
