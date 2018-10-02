class Processor
  attr_reader :finished
  def initialize(chunky_image, start_time = Time.now, target_color = ChunkyPNG::Color.rgba(248, 218, 69, 255))
    @blobs = []
    @finished = false
    @start_time = start_time
    @target_color = target_color

    @color_red  = ChunkyPNG::Color.r(@target_color)
    @color_green= ChunkyPNG::Color.g(@target_color)
    @color_blue = ChunkyPNG::Color.b(@target_color)

    Thread.new do
      $window.status = "B"
      load_image(chunky_image)
      $window.status = "D"
      process
    end
  end

  def load_image(chunky_image)
    @image = chunky_image

    twidth = 640.0
    theight= 360.0
    $window.status = "Scaling image to #{twidth}:#{theight}..."
    scale = [twidth/@image.width, theight/@image.height].min
    # puts "scale: #{scale}"
    width = @image.width * scale
    height= @image.height * scale

    @image.resample_bilinear!(width.to_i.clamp(1, twidth), height.to_i.clamp(1, theight))

    @out_image = @image.grayscale
    @old_out_image = @out_image.dup
  end

  def color_in_range(pixel, drift)
    if ChunkyPNG::Color.euclidean_distance_rgba(@target_color, pixel) < drift
      return true
    end
  end

  def distance(x,y, x2, y2)
    return Math.sqrt((x - x2)**2 + (y - y2)**2)
  end

  def process
    last_point = nil
    distance_threshold = 3
    color_distance = 80

    _progress_size = @image.width-2+@image.height-2
    for x in 1..@image.width-2
      for y in 1..@image.height-2
        $window.progressbar.progress=(((x+y).to_f / _progress_size) * 100)

        $window.status =  "#{x}:#{y}"
        pixel = @image.get_pixel(x, y)
        if color_in_range(pixel, color_distance)
          @old_out_image[x,y] = @target_color

          if last_point
            found_blob = false
            @blobs.detect do |blob|
              d = blob.distance_from(x, y)
              if d < distance_threshold && d > 0
                found_blob = true
                blob.add(x, y)
                break
              end
            end

            unless found_blob
              @blobs << Blob.new(x,y, x,y)
              # puts "Blobs #{@blobs.size}"
            end
          else
            @blobs << Blob.new(x,y, x,y)
          end

          last_point = [x,y]
        end
      end
    end

    clear_enclosed_blobs

    if @blobs.size > 0
      mask_color = ChunkyPNG::Color.rgba(@color_red, @color_green, @color_blue, 150)
      @blobs.each do |blob|
        @out_image.rect(blob.min_x, blob.min_y, blob.max_x, blob.max_y, ChunkyPNG::Color::WHITE, mask_color)
      end
    end

    $window.status = "Completed. Took #{(Time.now-@start_time).round(2)} seconds. Found #{@blobs.size} blobs."
    @finished = true
  end

  def clear_enclosed_blobs(list = @blobs)
    errors = Set.new
    search = 2 # Smaller is better

    list.each do |can|
      list.each do |blob|
        next if blob == can
        if   (can.min_x).between?(blob.min_x - search, blob.max_x + search) && (can.max_x).between?(blob.min_x - search, blob.max_x + search)
          if (can.min_y).between?(blob.min_y - search, blob.max_y + search) && (can.max_y).between?(blob.min_y - search, blob.max_y + search)
            errors.add(can)
            # @blobs.delete(can)
          end
        end
      end
    end

    if list.size != @blobs.size
      $window.status = "Fixing #{errors.size} errors..."
      list.each do |blob|
        list.each do |can|
          if (can.max_x - can.min_x) + (can.max_y - can.min_y) >= (blob.max_x - blob.min_x) + (blob.max_y - blob.min_y)
            blob.max_x = can.max_x
            blob.max_y = can.max_y

            @blobs.delete(can)
          end
        end
      end
      list.each {|b| @blobs.delete(b)}

      if errors.size > 0
        $window.status = "found #{errors.size} errors, fixing,,,"
        clear_enclosed_blobs(errors)
      end
    else
      if errors.size > 0
        $window.status = "found #{errors.size} errors, fixing..."
        clear_enclosed_blobs(errors)
      end
    end
  end

  def completed
    $window.main_image = Gosu::Image.new(Magick::Image.new(@image))
    $window.out_image = Gosu::Image.new(Magick::Image.new(@out_image))
    $window.old_out_image = Gosu::Image.new(Magick::Image.new(@old_out_image))
  end
end