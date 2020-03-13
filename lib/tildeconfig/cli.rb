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

      parser = OptionsParser.new
      options = parser.parse(ARGV)
      p ARGV
    end
  end
end
