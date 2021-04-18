module TildeConfig
  ##
  # A file that can be installed.
  class TildeFile
    attr_reader :src, :dest, :is_symlink

    ##
    # Creates a +TildeFile+ with the given +src+ and +dest+ paths.
    def initialize(src, dest, is_symlink: false)
      @src = src
      @dest = dest
      @is_symlink = is_symlink
    end
  end
end
