class Window < Gosu::Window

  attr_accessor :main_image, :out_image, :old_out_image, :progressbar, :status
  def initialize
    super(640*2+2, 1000+2, fullscreen: false, update_interval: 1000.0/20.0)
    self.caption = "Color Detection"
    $window = self

    p_width = self.width-4
    @progressbar = ProgressBar.new(self.width/2-p_width/2, 960, p_width, 40)
    @completion = 0.0

    @current_processor = nil
    @current_processor_finished = false
    @main_image, @out_image, @old_out_image = nil
    @scale = 0.3

    @font = Gosu::Font.new(28, name: "Consolas")
    @status = "Waiting..."
    @target_color = ChunkyPNG::Color.rgba(248, 218, 69, 255)
    @gosu_target_color = Gosu::Color.rgba(
      ChunkyPNG::Color.r(@target_color), # red
      ChunkyPNG::Color.g(@target_color), # green
      ChunkyPNG::Color.b(@target_color), # blue
      ChunkyPNG::Color.a(@target_color)  # alpha
    )
  end

  def draw
    # main frame
    Gosu.draw_rect(1, 1, self.width-2, 500, Gosu::Color::WHITE)
    scale = [self.width/@main_image.width, 500/@main_image.height].min.ceil if @main_image

    @main_image.draw(1,1,4, scale+@scale, scale+@scale) if @main_image

    # Split frame
    Gosu.draw_rect(1, 500+2, 640, 360, Gosu::Color::GREEN)
    @out_image.draw(1, 500+2, 4) if @out_image

    # Split frame
    Gosu.draw_rect(self.width/2+2, 500+2, 640-2, 360, Gosu::Color::RED)
    @old_out_image.draw(self.width/2+1, 500+2, 4) if @old_out_image

    Gosu.draw_rect(2, 260+640, 24, 24, @gosu_target_color)
    @font.draw(@status, self.width/2-@font.text_width(@status)/2, 260+640, 1)
    @progressbar.draw
  end

  def update
    if @current_processor && @current_processor.finished && !@current_processor_finished
      @current_processor.completed
      @current_processor_finished = true
    end
  end

  def button_up(id)
    close if id == Gosu::KbEscape
  end

  def drop(file)
    if @current_processor.nil?
      handle_image(file)
    elsif @current_processor && @current_processor.finished
      handle_image(file)
    else
      @status = "Processor is busy..."
    end
  end

  def handle_image(file)
    @status = "Loading #{File.basename(file)}..."

    _image = nil
    start_time = Time.now
    begin
    _image = Gosu::Image.new(file)
    rescue RuntimeError
      @status = "File is not an image or it is not supported."
      return
    end
    _rgba_stream = ChunkyPNG::Image.from_rgba_stream(_image.width, _image.height, _image.to_blob)

    @current_processor = Processor.new(_rgba_stream, start_time, @target_color)
    @current_processor_finished = false
    @progressbar.progress=0.0
  end

  def needs_cursor?
    true
  end
end