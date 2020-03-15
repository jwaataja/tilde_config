module Tildeconfig
  ##
  # Represents a mechanism for installing packages on a given system.
  class PackageInstaller
    ##
    # Constructs a +PackageInstaller+ that installs packages by yielding
    # to the provided block with an array of package names.
    def initialize(&install_proc)
      @install_proc = install_proc
    end

    ##
    # Installs the packages in the given array.
    def install(packages)
      @install_proc.call(packages)
    end
  end
end
