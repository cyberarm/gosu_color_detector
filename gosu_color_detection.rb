# begin
  require "oily_png"
# rescue LoadError
#   puts "Failing back to chunkyPNG..."
#   require "chunky_png"
# end

require "gosu"

require_relative "lib/window"
require_relative "lib/progressbar"
require_relative "lib/detection/blob"
require_relative "lib/detection/processor"
require_relative "lib/detection/gosu_magick"

Window.new.show