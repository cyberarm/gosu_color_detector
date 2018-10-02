class Processor
  def initialize(file)
    @blobs = []
    @image = ChunkyPNG::Image.from_file(file)

    twidth = 640.0
    theight= 360.0
    puts "Scaling image to #{twidth}:#{theight}..."
    scale = [twidth/@image.width, theight/@image.height].min
    puts "scale: #{scale}"
    width = @image.width * scale
    height= @image.height * scale

    @image.resample_bilinear!(width.to_i.clamp(1, twidth), height.to_i.clamp(1, theight))


    @target_color = ChunkyPNG::Color.rgba(248, 218, 69, 255) # Yellow
    # @target_color = ChunkyPNG::Color.rgba(231, 57, 73, 255) # Red
    # @target_color = ChunkyPNG::Color.rgba(255,255,255, 255)# White
    # @target_color = ChunkyPNG::Color.rgba(0,0,0, 255)# Black
    @color_red  = ChunkyPNG::Color.r(@target_color)
    @color_green= ChunkyPNG::Color.g(@target_color)
    @color_blue = ChunkyPNG::Color.b(@target_color)

    @out_image = @image.grayscale
    @old_out_image = @out_image.dup

    process
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

    for x in 1..@image.width-2
      for y in 1..@image.height-2
        # puts "X: #{x}:#{y}"
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

    completed
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
      puts "Fixing #{errors.size} errors..."
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
        puts "found #{errors.size} errors, fixing,,,"
        clear_enclosed_blobs(errors)
      end
    else
      if errors.size > 0
        puts "found #{errors.size} errors, fixing..."
        clear_enclosed_blobs(errors)
      end
    end
  end

  def completed
    if @blobs.size > 0
      mask_color = ChunkyPNG::Color.rgba(@color_red, @color_green, @color_blue, 150)
      @blobs.each do |blob|
        @out_image.rect(blob.min_x, blob.min_y, blob.max_x, blob.max_y, ChunkyPNG::Color::WHITE, mask_color)
      end
    end

    $window.main_image = Gosu::Image.new(Magick::Image.new(@image))
    $window.out_image = Gosu::Image.new(Magick::Image.new(@out_image))
    $window.old_out_image = Gosu::Image.new(Magick::Image.new(@old_out_image))
  end
end