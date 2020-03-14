module Tildeconfig
  ##
  # Object representing a module in tilde.config. Holds actions, files and
  # dependencies specified for the module.
  class TildeMod
    DEFAULT_INSTALL_DIR = Dir.home
    # utility tuple-like class
    TildeFile = Struct.new(:src, :dest)
    private_constant :DEFAULT_INSTALL_DIR, :TildeFile

    def initialize
      @deps = []
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
      @install_cmds.push(block)
    end

    ##
    # Run the given block as part of this module's uninstall action.
    #
    # The block will be given 0 arguments, and run in this module's context.
    def uninstall(&block)
      raise "missing block argument" unless block_given?
      @uninstall_cmds.push(block)
    end

    ##
    # Run the given block as part of this module's update action.
    #
    # The block will be given 0 arguments, and run in this module's context.
    def update(&block)
      raise "missing block argument" unless block_given?
      @update_cmds.push(block)
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
    # Get all commands to be executed as part of the install action.
    def install_cmds
      @install_cmds
    end

    ##
    # Get all commands to be executed as part of the uninstall action.
    def uninstall_cmds
      @uninstall_cmds
    end

    ##
    # Get all commands to be executed as part of the update action.
    def update_cmds
      @update_cmds
    end

    ##
    # Execute the install action for this module now.
    def execute_install
      install_cmds.each(&:call)
    end

    ##
    # Execute the uninstall action for this module now.
    def execute_uninstall
      uninstall_cmds.each(&:call)
    end

    ##
    # Execute the update action for this module now.
    def execute_update
      update_cmds.each(&:call)
    end

    ##
    # Adds a file to be installed to this module. If only one argument is given,
    # then it will be used for both source and destination. Source is relative
    # to repository root, or set root_dir. Destination is relative to home
    # directory, or dir set by install_dir.
    def file(src, dest=nil)
      dest = src if dest == nil
      file_tuple = TildeFile.new(src, dest)
      # used for back-propogation
      @files.push(file_tuple)

      install do
        run_file_install(file_tuple)
      end
      uninstall do
        run_file_uninstall(file_tuple)
      end
      update do
        run_file_install(file_tuple)
      end
    end

    # def_pkg is defined as a class method for modifying the TildeMod class.
    # It will later be added to global scope within scripts
    def self.def_cmd(name, &block)
      # the given block should take in (module, *other_args)
      define_method(name, ->(*args) { yield self, *args })
    end

    private

    ##
    # Method run to install a file. Used by TildeMod.file.
    def run_file_install(file_tuple)
      # TODO: this assumes that our working directory will always be the user's
      # settings repository.
      src = File.join(@root_dir, file_tuple.src)
      dest = File.join(@install_dir, file_tuple.dest)
      unless File.exist? src
        raise "missing source file #{src}"
      end
      if File.exists? dest and !File.file? dest
        raise "destination file #{dest} exists and is not a regular file"
      end
      puts "copying #{src} to #{dest}"
      File.open(src, 'r') do |src_stream|
        File.open(dest, 'w+') do |dest_stream|
          FileUtils.copy_stream src_stream, dest_stream
        end
      end
    end

    ##
    # Method run to uninstall a file. Used by TildeMod.file.
    def run_file_uninstall(file_tuple)
      dest = File.join @install_dir, file_tuple.dest
      if ask_yes_no "Delete #{dest}? [y/N] "
        FileUtils.rm dest
      end
      # remove empty directories
      dir = dest
      loop do
        # grab dir's parent
        dir = File.split(dir)[0]
        if Dir.empty? dir
          puts "Removing empty directory #{dir}"
          Dir.delete dir
        end
      end
    end

    ##
    # Make a repeating prompt for Y/n answer, with an empty answer defaulting to
    # no.  Returns true on yes, false on no or empty answer.
    def ask_yes_no(prompt)
      while true
        print prompt
        res = gets
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
