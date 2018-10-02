class ProgressBar
  attr_accessor :progress
  def initialize(x, y, width, height)
    @x,@y,@width,@height = x,y,width,height
    @progress = 0.0

    @font = Gosu::Font.new(28, name: "Arial", bold: true)
  end

  def draw
    width = (@width.to_f / 100.0) * @progress

    Gosu.draw_rect(@x-1, @y, @width+1, @height+1, Gosu::Color::WHITE)
    Gosu.draw_rect(@x, @y, width, @height, Gosu::Color.rgba(50, 150, 50, 200))

    @font.draw_text("#{@progress.round}%", $window.width/2 - 30, @y+7, 2, 1,1, Gosu::Color::BLACK)
  end
end