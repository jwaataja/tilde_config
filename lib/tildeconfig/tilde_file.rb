module TildeConfig
  # A file or directory that can be installed.
  class TildeFile
    # @return [String] the relative path to the source file
    attr_reader :src
    # @return [String] relative or absolute path to the location to
    #   install the file
    attr_reader :dest
    # @return [Boolean] if true, the file should be installed as a
    #   symlink
    attr_reader :is_symlink

    # Creates a +TildeFile+ with the given +src+ and +dest+ paths.
    # @param src [String] path to the source file
    # @param dest [String] path to the destination file
    # @param false [Boolean] if true, the file should be installed as a
    #   symlink
    # @return [TildeFile] a new +TildeFile+
    def initialize(src, dest, is_symlink: false)
      @src = src
      @dest = dest
      @is_symlink = is_symlink
    end
  end
end
