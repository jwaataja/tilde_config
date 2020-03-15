module Tildeconfig
  class FileInstallError < StandardError
    attr_reader :file

    def initialize(message, file)
      super(message)
      @file = file
    end
  end
end
