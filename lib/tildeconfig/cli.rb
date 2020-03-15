module Tildeconfig
  CONFIG_FILE_NAME = "tildeconfig"

  module CLI
    ##
    # Starts the main execution of the command line program.
    def self.run
      if !File.exist?(CONFIG_FILE_NAME)
        warn "Failed to find config file #{CONFIG_FILE_NAME}"
        exit
      end

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
      when "install"
        install(options)
      when "uninstall"
        uninstall(options)
      when "update"
        update(options)
      else
        puts "Unknown command #{command}"
      end
    end

    def self.install(options)
      succeeded = true
      Globals::MODULES.each do |name, m|
        puts "Installing #{name.to_s}"
        begin
          m.execute_install
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
      Globals::MODULES.each do |name, m|
        puts "Uninstalling #{name.to_s}"
        m.execute_uninstall
      end
    end

    def self.update(options)
      succeeded = true
      Globals::MODULES.each do |name, m|
        puts "Updating #{name.to_s}"
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
