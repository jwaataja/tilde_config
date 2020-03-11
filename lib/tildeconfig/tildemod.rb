module Tildeconfig
    class TildeMod
        def initialize
            @deps = []
            @root_dir = nil
            @files = []
            @install_cmds = []
            @uninstall_cmds = []
            @update_cmds = []
        end

        def install(&block)
            # install must be passed a block
            raise "missing block argument" unless block_given?
            # make a storeable lambda with the passed in block
            @install_cmds.push(lambda(&block))
        end
        def uninstall(&block)
            raise "missing block argument" unless block_given?
            @uninstall_cmds.push(lambda(&block))
        end
        def update(&block)
            raise "missing block argument" unless block_given?
            @update_cmds.push(lambda(&block))
        end

        # file is also a "base" command
        def root_dir(dir)
            @root_dir = dir
        end
        def file(src, dest=nil)
            if dest == nil
                dest = src
            end
            file_tuple = TildeFile.new(src, dest)
            # used for back-propogation
            @files.push(file_tuple)
            # TODO: also insert install/uninstall/update commands
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
