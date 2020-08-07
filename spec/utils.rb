module TildeConfigSpec
  class << self
    ##
    # Runs the block and suppress all output to standard input and output, which
    # are restored after block finishes executing.
    def suppress_output(&block)
      original_stdout = $stdout
      original_stderr = $stderr
      begin
        $stdout = File.open(File::NULL, 'w')
        $stderr = File.open(File::NULL, 'w')
        block.call
      ensure
        $stdout = original_stdout
        $stderr = original_stderr
      end
    end

    ##
    # Runs the TildeConfig command line program and executes the given block for
    # configuration. Passes +args+ as the command line arguments. No
    # configuration file is loaded.
    #
    # If +suppress_output+ is true, then suppress all output produced by running
    # TildeConfig.
    def run(args = [], suppress_output: true, &block)
      if suppress_output
        suppress_output do
          TildeConfig::CLI.run(args, load_config_file: false, &block)
        end
      else
        TildeConfig::CLI.run(args, load_config_file: false, &block)
      end
    end
  end
end
