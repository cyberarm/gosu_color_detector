class Window < Gosu::Window

  attr_accessor :main_image, :out_image, :old_out_image
  def initialize
    super(640*2+2, 1000+2, fullscreen: false, update_interval: 1000.0/20.0)
    self.caption = "Color Detection"
    $window = self

    p_width = self.width-4
    @progress = ProgressBar.new(self.width/2-p_width/2, 960, p_width, 40)
    @completion = 0.0

    @main_image, @out_image, @old_out_image = nil
    @scale = 0.3
  end

  def draw
    # main frame
    Gosu.draw_rect(1, 1, self.width-2, 500, Gosu::Color::WHITE)
    scale = [self.width/@main_image.width, 500/@main_image.height].min.ceil if @main_image

    @main_image.draw(1,1,4, scale+@scale, scale+@scale) if @main_image

    # Split frame
    Gosu.draw_rect(1,              500+2, 640, 360, Gosu::Color::GREEN)
    @out_image.draw(1,500+2,4) if @out_image

    # Split frame
    Gosu.draw_rect(self.width/2+2, 500+2, 640-2, 360, Gosu::Color::RED)
    @old_out_image.draw(self.width/2+1, 500+2,4) if @old_out_image

    @progress.draw
  end

  def update
    @completion+=rand(0.1..1.0)
    @completion = 0.0 if @completion > 100
    @progress.progress=@completion
  end

  def button_up(id)
    close if id == Gosu::KbEscape
  end

  def drop(file)
    if file.end_with?(".png")
      Processor.new(file)
    else
      puts "Unsupported file"
    end
  end

  def needs_cursor?
    true
  end
end