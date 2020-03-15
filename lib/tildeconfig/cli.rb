module Tildeconfig
  CONFIG_FILE_NAME = 'tildeconfig'

  ##
  # Methods for the tildeconfig command line interface.
  module CLI
    ##
    # Starts the main execution of the command line program.
    def self.run
      unless File.exist?(CONFIG_FILE_NAME)
        warn "Failed to find config file #{CONFIG_FILE_NAME}"
        exit
      end

      define_standard_library
      load(CONFIG_FILE_NAME)

      options = Options.new.parse(ARGV)
      begin
        options.validate
      rescue OptionsError => e
        warn "Invalid options: #{e.message}"
        exit false
      end

      if ARGV.empty?
        options.print_help
        exit
      end

      command = ARGV[0]
      case command
      when 'install'
        install(options)
      when 'uninstall'
        uninstall(options)
      when 'update'
        update(options)
      else
        puts "Unknown command #{command}"
      end
    end

    def self.install(options)
      succeeded = true
      Configuration.instance.modules.each do |name, m|
        puts "Installing #{name}"
        begin
          m.execute_install(options)
        rescue FileInstallError => e
          warn "Error while installing module #{name}."
          warn "Failed to install file #{e.file.src} to #{e.file.dest}: " \
            "#{e.message}"
          succeeded = false
        end
        exit false unless succeeded
      end
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
        exit false unless succeeded
      end
    end
  end
end
