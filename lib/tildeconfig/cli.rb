module Tildeconfig
  CONFIG_FILE_NAME = "tildeconfig"

  module CLI
    ##
    # Starts the main execution of the command line program.
    def self.run
      if !File.exist?(CONFIG_FILE_NAME)
        $stderr.puts "Failed to find config file #{CONFIG_FILE_NAME}"
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
          m.execute_install
        end
      else
          puts "Unknown command #{command}"
      end
    end
  end
end
