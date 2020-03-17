require 'set'

module Tildeconfig
  ##
  # Object representing a module in tilde.config. Holds actions, files and
  # dependencies specified for the module.
  class TildeMod
    DEFAULT_INSTALL_DIR = Dir.home

    private_constant :DEFAULT_INSTALL_DIR

    attr_reader :name, :install_cmds, :uninstall_cmds, :update_cmds, :files,
                :package_dependencies, :dependencies

    ##
    # Constructs a new module with the given name. The +dependencies+
    # is any collection of symbols naming modules the new module depends
    # on.
    def initialize(name, dependencies: [])
      @name = name
      @dependencies = Set.new(dependencies)
      @root_dir = '.'
      @install_dir = DEFAULT_INSTALL_DIR
      @files = []
      @install_cmds = []
      @uninstall_cmds = []
      @update_cmds = []
      @package_dependencies = Set.new
    end

    ##
    # Run the given block as part of this module's install action.
    #
    # The block will be given 0 arguments, and run in this module's context.
    def install(&block)
      # install must be passed a block
      raise 'missing block argument' unless block_given?

      @install_cmds << block
    end

    ##
    # Run the given block as part of this module's uninstall action.
    #
    # The block will be given 0 arguments, and run in this module's context.
    def uninstall(&block)
      raise 'missing block argument' unless block_given?

      @uninstall_cmds << block
    end

    ##
    # Run the given block as part of this module's update action.
    #
    # The block will be given 0 arguments, and run in this module's context.
    def update(&block)
      raise 'missing block argument' unless block_given?

      @update_cmds << block
    end

    ##
    # Set the root_dir for this module. All file source paths are relative to
    # the value set here. This is relative to the repository root.
    def root_dir(dir)
      dir = '.' if dir.nil?
      @root_dir = File.expand_path(dir)
    end

    ##
    # Set the install_dir for this module. All file dest paths are relative to
    # the value set here. `~` in the argument is automatically expanded to the
    # user's home directory.
    def install_dir(dir)
      dir = '~' if dir.nil?
      # expand relative to DEFAULT_INSTALL_DIR, not the current working
      # directory
      @install_dir = File.expand_path(dir, DEFAULT_INSTALL_DIR)
    end

    ##
    # Adds the given package as a dependency for this module.
    def pkg_dep(*packages)
      @package_dependencies.merge(packages)
    end

    ##
    # Execute the install action for this module now. Raises +FileInstallError+
    # when a file fails to install. Raises +PackageInstallError+ if a
    # package fails to install.
    def execute_install(options)
      install_dependencies(options) if options.packages
      @files.each { |file| run_file_install(file) }
      install_cmds.each(&:call)
    end

    ##
    # Execute the uninstall action for this module now.
    def execute_uninstall
      files.each { |file| run_file_uninstall(file) }
      uninstall_cmds.each(&:call)
    end

    ##
    # Execute the update action for this module now. Raises +FileInstallError+
    # when a file failes to install.
    def execute_update
      files.each { |file| run_file_install(file) }
      update_cmds.each(&:call)
    end

    def execute_refresh
      files.each do |file|
        src = src_path(file)
        dest = dest_path(file)
        unless File.exist?(src)
          puts "Warning: #{src} does not exist"
          next
        end
        unless File.file?(src)
          puts "Warning: #{src} is not a regular file"
          next
        end
        unless File.exist?(dest)
          puts "Warning: #{dest} does not exist, skipping"
          next
        end
        unless File.file?(dest)
          puts "Warning: #{dest} is not a regular file, skipping"
          next
        end
        next if FileUtils.compare_file(src, dest)

        proceed = ask_yes_no("Update #{src} in repository from #{dest}? [y/N]")
        cp(dest, src) if proceed
      end
    end

    ##
    # Adds a file to be installed to this module. If only one argument is given,
    # then it will be used for both source and destination. Source is relative
    # to repository root, or set root_dir. Destination is relative to home
    # directory, or dir set by install_dir.
    def file(src, dest = nil)
      dest = src if dest.nil?
      file_tuple = TildeFile.new(src, dest)
      @files << file_tuple
    end

    # def_pkg is defined as a class method for modifying the TildeMod class.
    # It will later be added to global scope within scripts
    def self.def_cmd(name)
      # the given block should take in (module, *other_args)
      define_method(name, ->(*args) { yield self, *args })
    end

    private

    ##
    # Method run to install a file. Used by TildeMod.file. Rasises an
    # +FileInstallError+ on failure.
    def run_file_install(file_tuple)
      # TODO: this assumes that our working directory will always be the user's
      # settings repository.
      src = src_path(file_tuple)
      dest = dest_path(file_tuple)
      unless File.exist?(src)
        raise FileInstallError.new("missing source file #{src}", file_tuple)
      end

      if File.exist?(dest) && File.directory?(dest)
        raise FileInstallError.new("can't install to non-directory #{dest}",
                                   file_tuple)
      end
      FileUtils.mkdir_p(File.dirname(dest))
      puts "Copying #{src} to #{dest}"
      FileUtils.cp(src, dest)
    end

    ##
    # Method run to uninstall a file. Used by TildeMod.file.
    def run_file_uninstall(file_tuple)
      dest = File.join(@install_dir, file_tuple.dest)
      FileUtils.rm(dest) if ask_yes_no("Delete #{dest}? [y/N] ")
      # remove empty directories
      dir = dest
      loop do
        # grab dir's parent
        dir = File.split(dir)[0]
        if Dir.empty?(dir)
          puts "Removing empty directory #{dir}"
          Dir.delete(dir)
        end
      end
    end

    ##
    # Make a repeating prompt for Y/n answer, with an empty answer defaulting to
    # no.  Returns true on yes, false on no or empty answer.
    def ask_yes_no(prompt)
      loop do
        print prompt
        res = $stdin.gets.chomp
        return true if res.start_with?(/yY/)
        return false if res.start_with?(/nN/) || res.strip.empty?

        puts "Please answer 'y' or 'n'."
      end
    end

    ##
    # Installs all package denpendencies. Prints a warning to the user if
    # there's that hasn't been definde with +def_package+. Rasises an
    # +PackageInstallError+ if any fail to install.
    def install_dependencies(options)
      system = options.system
      package_names = @package_dependencies.map do |package|
        find_package_name(package, system)
      end
      config = Configuration.instance
      unless config.installers[system].install(package_names)
        raise PackageInstallError, 'Failed to install package(s) ' \
          "#{package_names.join(', ')} for system #{system}"
      end
    end

    ##
    # Returns the package name for +package+ on +system+. If +package+ has no
    # +def_package+ or the package has no name on +system+, then returns
    # +package+ itself. In this case prints a warning to the user.
    def find_package_name(package, system)
      config = Configuration.instance
      unless config.system_packages.key?(package)
        puts %(Warning: package #{package} has no "def_package")
        return package
      end
      unless config.system_packages.fetch(package).on_system?(system)
        puts "Warning: package #{package} is not on system #{system}"
        return package
      end
      config.system_packages.fetch(package).name_for_system(system)
    end

    ##
    # Returns the full absolute source path for the given file object.
    def src_path(file)
      File.join(@root_dir, file.src)
    end

    ##
    # Returns the full absolute destination path for the given file object.
    def dest_path(file)
      File.join(@install_dir, file.dest)
    end
  end
end
