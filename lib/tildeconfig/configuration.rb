module TildeConfig
  ##
  # Represents the state of one run of the program, including modules,
  # installers, etc. Includes what would normally global variables.
  class Configuration
    # The +modules+ is a map from module names as symbols to the modules
    # themselves.  The +installers+ is a map from system names as symbols to the
    # +PackageInstaller+ for that system.  The +system_packages+ is a map from
    # package names as strings to the +SystemPackage+ for it.
    attr_reader :modules, :installers, :system_packages

    def initialize
      @modules = {}
      @installers = {}
      @system_packages = {}
    end

    class << self
      attr_writer :instance

      def instance
        @instance ||= new
      end

      # Makes these methods private to enforce singleton pattern
      private :instance=, :new
    end

    ##
    # Yields to the provided block with a temporary empty configuration. The
    # global configuration is reset to its origin state afterward. Returns the
    # result of the block.
    def self.with_empty_configuration
      old_configuration = instance
      self.instance = new
      begin
        yield
      ensure
        self.instance = old_configuration
      end
    end

    ##
    # Yields to the provided block with a temporary empty configuration. This
    # configuration will have standard library available. The global
    # configuration is reset to its origin state afterward. Returns the result
    # of the block.
    def self.with_standard_library
      old_configuration = instance
      self.instance = new
      define_standard_library
      begin
        yield
      ensure
        self.instance = old_configuration
      end
    end
  end
end
