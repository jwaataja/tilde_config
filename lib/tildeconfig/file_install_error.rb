module TildeConfig
  ##
  # An error when a file fails to install.
  class FileInstallError < ActionError
    attr_reader :file

    def initialize(message, file)
      super(message)
      @file = file
    end

    def print_warning
      warn "Failed to install file #{file.src} to #{file.dest}: " \
        "#{message}"
    end
  end
end
