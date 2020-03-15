##
# Defines a module with the given name if it doesn't already exist. If a block
# is provided, runs it and passes the module with the given name.
def mod(name)
  unless Tildeconfig::Globals::MODULES.key?(name)
    Tildeconfig::Globals::MODULES[name] = Tildeconfig::TildeMod.new
  end

  yield(Tildeconfig::Globals::MODULES[name]) if block_given?
end

##
# Runs +command+ as a shell command.
def sh(command)
  system(command)
end

##
# Defines a new system installer with the given name. To install packages, the
# installer yields to the provided block passing an array of packages. Overrides
# existing installers with the same name.
def def_installer(name, &block)
  Tildeconfig::Globals::INSTALLERS[name.to_sym] =
    Tildeconfig::PackageInstaller.new(&block)
end

##
# Defines a new package with the given name and system names. The +system_names+
# parameter is a hash from symbols representing package names to strings
# representing the name of the package on that system. Overrides existing
# package if exists.
def def_package(name, system_names)
  Tildeconfig::Globals::SYSTEM_PACKAGES[name] =
    Tildeconfig::SystemPackage.new(name, system_names)
end
