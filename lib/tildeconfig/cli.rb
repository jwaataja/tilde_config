module Tildeconfig
  CONFIG_FILE_NAME = 'tildeconfig'

  ##
  # Methods for the tildeconfig command line interface.
  module CLI
    ##
    # Starts the main execution of the command line program. The +args+ should
    # be the command line arguments to the program. Set +load_config_file+ to
    # false to prevent the default configuration file from being loaded. If a
    # block is provided, yields to it right after the configuration file would
    # be loaded but before the main program executes. Returns true on success,
    # false on failure.
    def self.run(args, load_config_file: true)
      if load_config_file && !File.exist?(CONFIG_FILE_NAME)
        warn "Failed to find config file #{CONFIG_FILE_NAME}"
        return false
      end

      Configuration.with_standard_library do
        load(CONFIG_FILE_NAME) if load_config_file

        yield if block_given?

        options = Options.new.parse(args)
        begin
          options.validate
        rescue OptionsError => e
          warn "Invalid options: #{e.message}"
          return false
        end

        if args.empty?
          options.print_help
          return false
        end

        command = args[0]
        modules = args.drop(1).map(&:to_sym)
        modules.each do |m|
          unless Configuration.instance.modules.key?(m)
            warn "Unknown module #{m}"
            return false
          end
        end
        case command
        when 'install'
          install(modules, options)
        when 'uninstall'
          uninstall(options)
        when 'update'
          update(options)
        else
          puts "Unknown command #{command}"
          false
        end
      end
    end

    def self.install(modules, options)
      succeeded = true
      modules = Configuration.instance.modules.each_key if modules.empty?
      modules.each do |name|
        m = Configuration.instance.modules[name]
        puts "Installing #{name}"
        begin
          m.execute_install(options)
        rescue FileInstallError => e
          warn "Error while installing module #{name}."
          warn "Failed to install file #{e.file.src} to #{e.file.dest}: " \
            "#{e.message}"
          succeeded = false
        end
        return false unless succeeded
      end
      true
    end

    def self.uninstall(options)
      Configuration.instance.modules.each do |name, m|
        puts "Uninstalling #{name}"
        m.execute_uninstall
      end
    end

    def self.update(options)
      succeeded = true
      Configuration.instance.modules.each do |name, m|
        puts "Updating #{name}"
        begin
          succeeded = m.execute_update
        rescue FileInstallError => e
          warn "Error while updating module #{name}."
          warn "Failed to install file #{e.file.src} to #{e.file.dest}: " \
            "#{e.message}"
          succeeded = false
        end
        ereturn false unless succeeded
      end
      true
    end
  end
end
