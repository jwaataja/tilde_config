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
      if ARGV.empty?
        options.print_help
        exit
      end

      command = ARGV[0]
      case command
      when "install"
        MODULES.each do |name, m|
          puts "Installing #{name.to_s}"
          succeeded = m.execute_install
          unless succeeded
            warn "Error while installing #{name}"
            exit false
          end
        end
      when "uninstall"
        MODULES.each do |name, m|
          puts "Uninstalling #{name.to_s}"
          succeeded = m.execute_uninstall
          unless succeeded
            warn "Error while updating #{name}"
            exit false
          end
        end
      when "update"
        MODULES.each do |name, m|
          puts "Updating #{name.to_s}"
          succeeded = m.execute_update
          unless succeeded
            warn "Error while updating #{name}"
            exit false
          end
        end
      else
          puts "Unknown command #{command}"
      end
    end
  end
end
