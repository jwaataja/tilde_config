module Tildeconfig
  CONFIG_FILE_NAME = "tildeconfig"

  module CLI
    def self.run
      if !File.exist?(CONFIG_FILE_NAME)
        $stderr.puts "Failed to find config file #{CONFIG_FILE_NAME}"
        return
      end

      load(CONFIG_FILE_NAME)
    end
  end
end
