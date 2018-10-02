class Blob
  attr_accessor :min_x, :min_y, :max_x, :max_y, :width, :height
  def initialize(min_x, min_y, max_x, max_y)
    @min_x, @min_y, @max_x, @max_y = min_x, min_y, max_x, max_y
    @width, @height = 1,1
  end

  def distance_from(x, y)
    min = Math.sqrt((@min_x - x)**2 + (@min_y - y)**2)
    max = Math.sqrt((@max_x - x)**2 + (@max_y - y)**2)

    if min < max
      return min
    else
      return max
    end
  end

  def add(x, y)
    @max_x = x
    @max_y = y

    @width = @max_x - @min_x
    @height = @max_y - @min_y
  end
end