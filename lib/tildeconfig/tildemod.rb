module Tildeconfig
    ##
    # Object representing a module in tilde.config. Holds actions, files and dependencies specified
    # for the module.
    class TildeMod
        def initialize
            @deps = []
            @root_dir = nil
            @install_dir = nil
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
            @install_cmds.push(lambda(&block))
        end

        ##
        # Run the given block as part of this module's uninstall action.
        #
        # The block will be given 0 arguments, and run in this module's context.
        def uninstall(&block)
            raise "missing block argument" unless block_given?
            @uninstall_cmds.push(lambda(&block))
        end

        ##
        # Run the given block as part of this module's update action.
        #
        # The block will be given 0 arguments, and run in this module's context.
        def update(&block)
            raise "missing block argument" unless block_given?
            @update_cmds.push(lambda(&block))
        end

        # file is also a "base" command
        def root_dir(dir)
            if dir.nil?
                @root_dir = '.'
            else
                @root_dir = dir
            end
        end
        def install_dir(dir)
            if dir.nil?
                @install_dir = '.'
            else
                @install_dir = dir
            end
        end
        def file(src, dest=nil)
            if dest == nil
                dest = src
            end
            file_tuple = TildeFile.new(src, dest)
            # used for back-propogation
            @files.push(file_tuple)

            install do
                run_file_install file_tuple
            end
            uninstall do
                run_file_uninstall file_tuple
            end
            update do
                run_file_install file_tuple
            end
        end

        ### Methods defining file behavior. This should probably be moved into a separate file
        def run_file_install(file_tuple)
            # TODO
        end
        def run_file_uninstall(file_tuple)
            # TODO
        end

        # def_pkg is defined as a class method for modifying the TildeMod class.
        # It will later be added to global scope within scripts
        def self.def_cmd(name, &block)
            # the given block should take in (module, *other_args)
            define_method(name, ->(*args) { yield self, *args })
        end

        # utility tuple-like class
        TildeFile = Struct.new(:src, :dest)
        private_constant :TildeFile
    end
end
