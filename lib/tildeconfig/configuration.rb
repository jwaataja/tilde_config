module TildeConfig
  # Represents the state of one run of the program, including settings, modules,
  # installers, etc. Includes what would normally global variables.
  class Configuration
    # @return [Hash<Symbol, TildeMod>] map from module names as symbols to the
    #   their modules
    attr_reader :modules
    # @return [Hash<Symbol, PackageInstaller>] map from system names as symbols
    #   to the +PackageInstaller+ for that system
    attr_reader :installers
    # @return [Hash<String, SystemPackage> map from package names as strings to
    #   the +SystemPackage+ for it
    attr_reader :system_packages
    # @return [Settings] the settings for the configuration
    attr_reader :settings

    def initialize
      @modules = {}
      @installers = {}
      @system_packages = {}
      @settings = Settings.new
    end

    class << self
      attr_writer :instance

      def instance
        @instance ||= new
      end

      # Makes these methods private to enforce singleton pattern
      private :instance=, :new
    end

    # Yields to the provided block with a temporary empty configuration. The
    # global configuration is reset to its origin original state afterward.
    # Returns the result of the block. Can also pass initial settings for the
    # configuration.
    # @param settings [Hash<Symbol, Object>] map from symbols representing
    #   setting names to values for that setting that the configuration will
    #   have
    def self.with_empty_configuration(settings = {})
      old_configuration = instance
      self.instance = new
      instance.settings.set_settings(settings)
      begin
        yield
      ensure
        self.instance = old_configuration
      end
    end

    # Yields to the provided block with a temporary empty configuration. This
    # configuration will have standard library available. The global
    # configuration is reset to its original state afterward. Returns the result
    # of the block. Can also pass initial settings for the
    # configuration.
    # @param settings [Hash<Symbol, Object>] map from symbols representing
    #   setting names to values for that setting that the configuration will
    #   have
    def self.with_standard_library(settings = {})
      old_configuration = instance
      self.instance = new
      instance.settings.set_settings(settings)
      define_standard_library
      begin
        yield
      ensure
        self.instance = old_configuration
      end
    end
  end
end
