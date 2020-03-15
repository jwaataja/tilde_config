module Tildeconfig
  ##
  # Stores constants shared throughout one execution of the program.
  module Globals
    ##
    # Map from module names as symbols to the modules themselves.
    MODULES = {}

    ##
    # Map from system names as strings to the +PackageInstaller+ for that
    # system.
    INSTALLERS = {}
  end
end
