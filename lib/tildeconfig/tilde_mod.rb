

module Tildeconfig
  ##
  # Object representing a module in tilde.config. Holds actions, files and
  # dependencies specified for the module.
  class TildeMod
    DEFAULT_INSTALL_DIR = Dir.home

    private_constant :DEFAULT_INSTALL_DIR

    attr_reader :install_cmds, :uninstall_cmds, :update_cmds, :files,
      :package_dependencies

    def initialize
      @root_dir = "."
      @install_dir = DEFAULT_INSTALL_DIR
      @files = []
      @install_cmds = []
      @uninstall_cmds = []
      @update_cmds = []
    end

    ##
    # Run the given block as part of this module's install action.
    #
    # The block will be given 0 arguments, and run in this module's context.
    def install(&block)
      # install must be passed a block
      raise "missing block argument" unless block_given?
      # make a storeable lambda with the passed in block
      @install_cmds << block
    end

    ##
    # Run the given block as part of this module's uninstall action.
    #
    # The block will be given 0 arguments, and run in this module's context.
    def uninstall(&block)
      raise "missing block argument" unless block_given?
      @uninstall_cmds << block
    end

    ##
    # Run the given block as part of this module's update action.
    #
    # The block will be given 0 arguments, and run in this module's context.
    def update(&block)
      raise "missing block argument" unless block_given?
      @update_cmds << block
    end

    ##
    # Set the root_dir for this module. All file source paths are relative to
    # the value set here. This is relative to the repository root.
    def root_dir(dir)
      dir = "." if dir.nil?
      @root_dir = File.expand_path(dir)
    end

    ##
    # Set the install_dir for this module. All file dest paths are relative to
    # the value set here. `~` in the argument is automatically expanded to the
    # user's home directory.
    def install_dir(dir)
      dir = "~" if dir.nil?
      # expand relative to DEFAULT_INSTALL_DIR, not the current working
      # directory
      @install_dir = File.expand_path(dir, DEFAULT_INSTALL_DIR)
    end

    ##
    # Execute the install action for this module now. Raises +FileInstallError+
    # when a file fails to install.
    def execute_install
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

    ##
    # Adds a file to be installed to this module. If only one argument is given,
    # then it will be used for both source and destination. Source is relative
    # to repository root, or set root_dir. Destination is relative to home
    # directory, or dir set by install_dir.
    def file(src, dest = nil)
      dest = src if dest == nil
      file_tuple = TildeFile.new(src, dest)
      @files << file_tuple
    end

    # def_pkg is defined as a class method for modifying the TildeMod class.
    # It will later be added to global scope within scripts
    def self.def_cmd(name, &block)
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
      src = File.join(@root_dir, file_tuple.src)
      dest = File.join(@install_dir, file_tuple.dest)
      unless File.exists?(src)
        raise FileInstallError.new("missing source file #{src}", file_tuple)
      end
      if File.exists?(dest) && File.directory?(dest)
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
        res = gets.chomp
        if res.start_with?(/yY/)
          return true
        elsif res.start_with?(/nN/) || res.strip.empty?
          return false
        else
          puts "Please answer 'y' or 'n'."
        end
      end
    end
  end
end
