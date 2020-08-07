require 'fileutils'
require 'pathname'
require 'set'

module TildeConfig
  ##
  # Object representing a module in tilde.config. Holds actions, files and
  # dependencies specified for the module.
  class TildeMod
    DEFAULT_INSTALL_DIR = Dir.home

    private_constant :DEFAULT_INSTALL_DIR

    attr_reader :name, :install_cmds, :uninstall_cmds, :update_cmds,
                :package_dependencies, :dependencies

    ##
    # Array of +TildeFile+ objects to install.
    attr_reader :files

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
    # when a file fails to install. Raises an +ActionError+ if some action
    # fails, unless --ignore-errors is specified.
    def execute_install(options)
      ActionError.print_warn_if_no_ignore(options) do
        install_system_dependencies(options) if options.packages
      end
      files.each do |file|
        ActionError.print_warn_if_no_ignore(options) do
          run_file_install(file, options)
        end
      end
      execute_command_list(install_cmds, options)
    end

    ##
    # Execute the uninstall action for this module now. Raises an +ActionError+
    # if some action fails, unless --ignore-errors is specified.
    def execute_uninstall(options)
      files.each do |file|
        ActionError.print_warn_if_no_ignore(options) do
          run_file_uninstall(file)
        end
      end
      execute_command_list(uninstall_cmds, options)
    end

    ##
    # Execute the update action for this module now. Raises an +ActionError+ if
    # some action fails, unless --ignore-errors is specified.
    def execute_update(options)
      files.each do |file|
        ActionError.print_warn_if_no_ignore(options) do
          run_file_install(file, options)
        end
      end
      execute_command_list(update_cmds, options)
    end

    # TODO: Comment this.
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

        proceed = ask_yes_no("Update #{src} in repository from #{dest}? [y/N] ")
        puts "Copying #{dest} to #{src}"
        FileUtils.cp(dest, src) if proceed
      end
    end

    ##
    # Retrieves an array of this package's full set of dependencies,
    # recursively resolved, in no particular order. Result includes this
    # package.
    def all_dependencies
      result = Set.new
      visited = Set.new
      all_dependencies_helper(@name, visited, result)
      result.to_a
    end

    ##
    # Adds a file to this module. The source path should be a file path relative
    # to the module root directory. The +dest+ represents the location the file
    # will be installed, including its basename (it's not just the directory).
    # If it's relative, then the file is installed relative to the module
    # install directory. If +dest+ is not given, then the file is installed to
    # the same relative path in the module install directory as the source file
    # is in the module root directory.
    def file(src, dest = nil)
      dest = src if dest.nil?
      @files << TildeFile.new(src, dest)
    end

    ##
    # Takes a shell glob pattern string +src_pattern+ and an optional
    # destination directory path +dest_dir+.
    #
    # Adds each file matching +src_pattern+. If +dest_dir+ is given, then
    # installs each file directly into +dest_dir+ with the same basename as the
    # source file. If +dest_dir+ is not given, then installs into the default
    # installation directory with the same relative path as the source file.
    #
    # Relative paths are resolved relative to the result of +root_dir+, so set
    # it before calling this method.
    def file_glob(src_pattern, dest_dir = nil)
      Dir.glob(src_pattern, base: @root_dir) do |src|
        dest_path = if dest_dir.nil?
                      src
                    else
                      File.join(dest_dir, File.basename(src))
                    end
        file(src, dest_path)
      end
    end

    ##
    # Same as file, but expects a directory as the source.
    def directory(src, dest = nil)
      file(src, dest)
    end

    private

    # Takes an enumerable collection of callable objects in +commands+ and
    # executes them in order. Expects that each command performs one action to
    # install, update, or remove a module.
    #
    # The +options+ parameter is an +Options+ that holds the command line
    # arguments.
    #
    # Raises an +ActionError+ if some action fails, unless --ignore-errors is
    # specified.
    def execute_command_list(commands, options)
      commands.each do |command|
        ActionError.print_warn_if_no_ignore(options) { command.call }
      end
    end

    ##
    # Adds +module_name+ and all its dependencies (calculated recursive) to
    # +result+ using +visited+ to prevent visiting the same module twice.
    def all_dependencies_helper(module_name, visited, result)
      result << module_name
      config = Configuration.instance
      config.modules.fetch(module_name).dependencies.each do |dependency|
        next if visited.include?(dependency)

        visited << dependency
        all_dependencies_helper(dependency, visited, result)
      end
    end

    ##
    # Method run to install a file. Used by TildeMod.file. Rasises an
    # +FileInstallError+ on failure.
    def run_file_install(file_tuple, options)
      # TODO: this assumes that our working directory will always be the user's
      # settings repository.
      src = src_path(file_tuple)
      dest = dest_path(file_tuple)
      FileInstallUtils.install(
        file_tuple,
        src,
        dest,
        merge_strategy: options.directory_merge_strategy,
        should_override: options.should_override
      )
    end

    ##
    # Method run to uninstall a file. Used by TildeMod.file.
    def run_file_uninstall(file_tuple)
      dest = File.join(@install_dir, file_tuple.dest)
      FileUtils.rm(dest) if ask_yes_no("Delete #{dest}? [y/N] ")
      # remove empty directories
      # dir = dest
      # loop do
      #   # grab dir's parent
      #   dir = File.split(dir)[0]
      #   if Dir.empty?(dir)
      #     puts "Removing empty directory #{dir}"
      #     Dir.delete(dir)
      #   end
      # end
    end

    ##
    # Make a repeating prompt for Y/n answer, with an empty answer defaulting to
    # no.  Returns true on yes, false on no or empty answer.
    def ask_yes_no(prompt)
      loop do
        print prompt
        res = $stdin.gets.chomp
        return true if res.start_with?(/y/i)
        return false if res.start_with?(/n/i) || res.strip.empty?

        puts "Please answer 'y' or 'n'."
      end
    end

    ##
    # Installs all package denpendencies. Prints a warning to the user if
    # there's that hasn't been definde with +def_package+. Rasises an
    # +PackageInstallError+ if any fail to install.
    def install_system_dependencies(options)
      system = options.system
      package_names = @package_dependencies.map do |package|
        find_package_name(package, system)
      end
      config = Configuration.instance
      return if config.installers[system].install(package_names)

      raise PackageInstallError, 'Failed to install package(s) ' \
        "#{package_names.join(', ')} for system #{system}"
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
    # Returns the full source path for the given +TildeFile+.
    def src_path(file_tuple)
      if File.absolute_path?(file_tuple.src)
        file_tuple.src
      else
        File.join(@root_dir, file_tuple.src)
      end
    end

    ##
    # Returns the full destination path for the given +TildeFile+.
    def dest_path(file_tuple)
      if File.absolute_path?(file_tuple.dest)
        file_tuple.dest
      else
        File.join(@install_dir, file_tuple.dest)
      end
    end
  end
end
