module Tildeconfig
  ##
  # Represents a mechanism for installing packages on a given system.
  class PackageInstaller
    ##
    # Constructs a +PackageInstaller+ that installs packages by yielding
    # to the provided block with an array of package names. Should return
    # whether package installation suceeded.
    def initialize(&install_proc)
      @install_proc = install_proc
    end

    ##
    # Installs the packages in the given array. Returns whether the installation
    # suceeded.
    def install(packages)
      @install_proc.call(packages)
    end
  end
end
