module TildeConfig
  ##
  # Represents a software package that may be installed on an operating system,
  # usually by a package manager.
  class SystemPackage
    attr_reader :name

    ##
    # Constructs a +SystemPackage+ with the given name and syste names.
    # The +system_names+ is a hash mapping system names to the name of
    # the package on that system.
    def initialize(name, system_names = {})
      @name = name
      @system_names = system_names.dup
    end

    ##
    # Returns whether this package has a name on the given system.
    def on_system?(system)
      @system_names.key?(system)
    end

    ##
    # Returns the name of this packagge on the given system if it
    # exists, or nil otherwise.
    def name_for_system(system)
      @system_names[system]
    end
  end
end
