module Tildeconfig
  ##
  # Stores constants shared throughout one execution of the program.
  module Globals
    ##
    # Map from module names as symbols to the modules themselves.
    MODULES = {}

    ##
    # Map from system names as symbols to the +PackageInstaller+ for that
    # system.
    INSTALLERS = {}

    ##
    # Map from package names as strings to the +SystemPackage+ for it.
    SYSTEM_PACKAGES = {}
  end
end
