module TildeConfig
  ##
  # A file that can be installed.
  class TildeFile
    attr_reader :src, :dest

    ##
    # Creates a +TildeFile+ with the given +src+ and +dest+ paths.
    def initialize(src, dest)
      @src = src
      @dest = dest
    end
  end
end
