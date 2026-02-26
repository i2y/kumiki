module Kumiki
  # rbs_inline: enabled

  # Spacer - flexible space widget

  class Spacer < Widget
    def initialize
      super
      @width_policy = EXPANDING
      @height_policy = EXPANDING
    end
  end

  # Top-level helper
  #: () -> Spacer
  def Spacer()
    Spacer.new
  end

end
