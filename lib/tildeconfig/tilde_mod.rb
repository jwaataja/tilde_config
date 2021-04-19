require 'fileutils'
require 'pathname'
require 'set'

module TildeConfig
  # Object representing a module in +tilde.config+. Holds actions, files and
  # dependencies specified for the module.
  class TildeMod
    # @return [String] the default directory configuration files should be
    # installed to
    DEFAULT_INSTALL_DIR = Dir.home

    private_constant :DEFAULT_INSTALL_DIR

    # @return [String] the name of the module within the DSL
    attr_reader :name
    # @return [Array<#call>] a list of callable objects to be run when
    #   installing this module
    attr_reader :install_cmds
    # @return [Array<#call>] a list of callable objects to be run when
    #   uninstalling this module
    attr_reader :uninstall_cmds
    # @return [Array<#call>] a list of callable objects to be run when
    #   updating this module
    attr_reader :update_cmds
    # @return [Set<Symbol>] a set of symbols for the names of modules this
    #   module dependens on
    attr_reader :dependencies
    # @return [Set<String>] a set of strings representing software packages that
    #   must be installed on the host system for this module to work
    attr_reader :package_dependencies
    # @return [Array<TildeFile>] array of +TildeFile+s associated with this
    #   module must be installed and kept up to date.
    attr_reader :files

    # Constructs a new module with the given name.
    # @param name [Symbol] the name of the module
    # @param dependencies [Array<Symbol>] collection of symbols naming modules
    #   the new module depends on.
    # @return [TildeMod] a new +TildeMod+
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

    # Run the given block as part of this module's install action. The block
    # will be given 0 arguments, and run in this module's context.
    def install(&block)
      raise 'missing block argument' unless block_given?

      @install_cmds << block
    end

    # Run the given block as part of this module's uninstall action. The block
    # will be given 0 arguments, and run in this module's context.
    def uninstall(&block)
      raise 'missing block argument' unless block_given?

      @uninstall_cmds << block
    end

    # Run the given block as part of this module's update action. The block
    # will be given 0 arguments, and run in this module's context.
    def update(&block)
      raise 'missing block argument' unless block_given?

      @update_cmds << block
    end

    # Set the root directory for this module, the directory where configuration
    # files to install are taken from. All file source paths are relative to the
    # value set here, and this path is relative to the repository root.
    # @param dir [String] path to the directory with configuration files
    def root_dir(dir)
      dir = '.' if dir.nil?
      @root_dir = File.expand_path(dir)
    end

    # Set the installation directory for this module. All file dest paths are
    # relative to the value set here. A +~+ in the argument is automatically
    # expanded to the user's home directory.
    # @param dir [String] path to the directory where files should be installed
    #   to.
    def install_dir(dir)
      dir = '~' if dir.nil?
      # expand relative to DEFAULT_INSTALL_DIR, not the current working
      # directory
      @install_dir = File.expand_path(dir, DEFAULT_INSTALL_DIR)
    end

    # Adds the given package as a dependency for this module.
    # @param packages [Array<String>] collection of packages this module will
    #   depend on
    def pkg_dep(*packages)
      @package_dependencies.merge(packages)
    end

    # Execute the install action for this module now. Raises +FileInstallError+
    # when a file fails to install. Raises an +ActionError+ if some action
    # fails, unless --ignore-errors is specified in +options+.
    # @param options [Options] the program options to use when installing
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

    # Execute the uninstall action for this module now. Raises an +ActionError+
    # if some action fails, unless --ignore-errors is specified.
    # @param options [Options] the program options to use when uninstalling
    def execute_uninstall(options)
      files.each do |file|
        ActionError.print_warn_if_no_ignore(options) do
          run_file_uninstall(file)
        end
      end
      execute_command_list(uninstall_cmds, options)
    end

    # Execute the update action for this module now. Raises an +ActionError+ if
    # some action fails, unless --ignore-errors is specified.
    # @param options [Options] the program options to use when updating
    def execute_update(options)
      files.each do |file|
        ActionError.print_warn_if_no_ignore(options) do
          run_file_install(file, options)
        end
      end
      execute_command_list(update_cmds, options)
    end

    # Execute refresh action for this module. For each file that differs between
    # the installed version and version stored locally, asks the user if they
    # want to update the locally stored version and copies it if the user says
    # "yes".
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

    # Retrieves an array of this package's full set of dependencies, recursively
    # resolved.
    # @return [Array<Symbol>] the list of dependencies for this module, in no
    #   particular order, and including this module
    def all_dependencies
      result = Set.new
      visited = Set.new
      all_dependencies_helper(@name, visited, result)
      result.to_a
    end

    # Adds a file to this module. The source path should be a file path relative
    # to the module root directory. The +dest+ represents the location the file
    # will be installed, including its basename (it's not just the directory).
    # If it's relative, then the file is installed relative to the module
    # install directory. If +dest+ is not given, then the file is installed to
    # the same relative path in the module install directory as the source file
    # is in the module root directory.
    # @param src [String] relative path to the file to install in the root
    #   directory for this repository
    # @param dest [String] either an absolute path or an absolute path relative
    #   to the installation directory for this module
    def file(src, dest = nil)
      # TODO: Check if src is a relative path here, and in other
      # commands
      file_helper(src, dest, false)
    end

    # Like the +file+ command, but creates a symlink instead.
    # @param src [String] relative path to the file to install in the root
    #   directory for this repository
    # @param dest [String] either an absolute path or an absolute path relative
    #   to the installation directory for this module
    def file_sym(src, dest = nil)
      file_helper(src, dest, true)
    end

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
    # @param src_pattern [String] a file glob pattern representing files to
    #   install
    # @param dest_dir [String, nil] if not nil, the directory to install the
    #   files to
    def file_glob(src_pattern, dest_dir = nil)
      file_glob_helper(src_pattern, dest_dir, false)
    end

    # Like the +file_glob+ command, but installs all files as symlinks
    # instead.
    # @param src_pattern [String] a file glob pattern representing files to
    #   install
    # @param dest_dir [String, nil] if not nil, the directory to install the
    #   files to
    def file_glob_sym(src_pattern, dest_dir = nil)
      file_glob_helper(src_pattern, dest_dir, true)
    end

    # Same as file, but expects a directory as the source.
    # @param src [String] path to a directory to install
    # @param dest [String, nil] path to the location the directory should be
    #   installed as
    def directory(src, dest = nil)
      file(src, dest)
    end

    # Same as file_sym, but expects a directory as the source.
    # @param src [String] path to a directory to install
    # @param dest [String, nil] path to the location the directory should be
    #   installed as
    def directory_sym(src, dest = nil)
      file_sym(src, dest)
    end

    private

    # Shared behavior of the +file+ and +file_sym+ commands that differs
    # in whether it uses symlinks.
    # @param src [String] relative path to the file to install in the root
    #   directory for this repository
    # @param dest [String, nil] either an absolute path or an absolute
    #   path relative to the installation directory for this module
    # @param is_symlink [Boolean] if true, installs the file as a
    #   symlink
    def file_helper(src, dest, is_symlink)
      dest = src if dest.nil?
      @files << TildeFile.new(src, dest, is_symlink: is_symlink)
    end

    # Shared behavior of +file_glob+ and +file_glob_sym+ that differs in
    # whether it uses symlinks.
    # @param src_pattern [String] a file glob pattern representing files to
    #   install
    # @param dest_dir [String, nil] if not nil, the directory to install the
    #   files to
    # @param use_symlinks [Boolean] if true, installs files with symlinks
    def file_glob_helper(src_pattern, dest_dir, use_symlinks)
      Dir.glob(src_pattern, base: @root_dir) do |src|
        dest_path = if dest_dir.nil?
                      src
                    else
                      File.join(dest_dir, File.basename(src))
                    end
        if use_symlinks
          file_sym(src, dest_path)
        else
          file(src, dest_path)
        end
      end
    end

    # Takes an enumerable collection of callable objects in +commands+ and
    # executes them in order. Expects that each command performs one action to
    # install, update, or remove a module.
    #
    # The +options+ parameter is an +Options+ that holds the command line
    # arguments.
    #
    # Raises an +ActionError+ if some action fails, unless --ignore-errors is
    # specified.
    # @param commands [Array<#call>] array of commands to execute
    # @param options [Options] the program options to use when performing the
    #   commands
    def execute_command_list(commands, options)
      commands.each do |command|
        ActionError.print_warn_if_no_ignore(options) { command.call }
      end
    end

    # Adds +module_name+ and all its dependencies (calculated recursive) to
    # +result+ using +visited+ to prevent visiting the same module twice.
    # @param module_name [Symbol] name of a module to explore
    # @param visited [Set<Symbol>] set of modules already visited
    # @param result [Set<Symbol>] result to add explored modules to
    def all_dependencies_helper(module_name, visited, result)
      result << module_name
      config = Configuration.instance
      config.modules.fetch(module_name).dependencies.each do |dependency|
        next if visited.include?(dependency)

        visited << dependency
        all_dependencies_helper(dependency, visited, result)
      end
    end

    # Method run to install a file. Used by TildeMod.file. Rasises a
    # +FileInstallError+ on failure.
    # @param file_tuple [TildeFile] the file to install
    # @param options [Options] options to use when installing
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

    # Method run to uninstall a file. Used by TildeMod.file.
    # @param file_tuple [TildeFile] the file to uninstall
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

    # Make a repeating prompt for Y/n answer, with an empty answer defaulting to
    # no.
    # @param prompt [String] the prompt to display to the user
    # @return [Boolean] true if the user answered yes, false otherwise
    def ask_yes_no(prompt)
      loop do
        print prompt
        res = $stdin.gets.chomp
        return true if res.start_with?(/y/i)
        return false if res.start_with?(/n/i) || res.strip.empty?

        puts "Please answer 'y' or 'n'."
      end
    end

    # Installs all package denpendencies. Prints a warning to the user if
    # there's that hasn't been definde with +def_package+. Rasises an
    # +PackageInstallError+ if any fail to install.
    # @param options [Options] options to use when installing dependencies
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

    # Returns the package name for +package+ on +system+. If +package+ has no
    # +def_package+ or the package has no name on +system+, then returns
    # +package+ itself. In this case prints a warning to the user.
    # @param package [String] name of package to find
    # @param system [Symbol] the system to find the package on
    # @return the name of +package+ on +system+ if it was found, or +package+
    #   otherwise
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

    # Returns the full source path for the given +TildeFile+.
    # @param file_tuple [TildeFile] file to expand source path of
    # @return [String] the full source path for +file_tuple+
    def src_path(file_tuple)
      if File.absolute_path?(file_tuple.src)
        file_tuple.src
      else
        File.join(@root_dir, file_tuple.src)
      end
    end

    # Returns the full destination path for the given +TildeFile+.
    # @param file_tuple [TildeFile] file to expand destination path of
    # @return [String] the full destination path for +file_tuple+
    def dest_path(file_tuple)
      if File.absolute_path?(file_tuple.dest)
        file_tuple.dest
      else
        File.join(@install_dir, file_tuple.dest)
      end
    end
  end
end
