require 'optparse'

module TildeConfig
  ##
  # Stores the options for the current run of the program.
  class Options
    attr_accessor :interactive, :system, :packages, :skip_dependencies

    def initialize
      self.interactive = true
      self.system = nil
      self.packages = false
      self.skip_dependencies = false
      @parser = OptionParser.new do |parser|
        define_options(parser)
      end
    end

    def define_options(parser)
      parser.banner = 'Usage: tildeconfig command [options]'
      parser.separator('')
      parser.separator('options:')

      parser.on('-n', '--non-interactive',
                'Automatically accept prompts') do
        self.interactive = false
      end
      parser.on('-s', '--system SYSTEM',
                'Set which system installer to use') do |s|
        self.system = s.to_sym
      end
      parser.on('--print-systems',
                'Print out the available systems with installers') do
        config = Configuration.instance
        config.installers.each_key { |name| puts name }
        exit
      end
      parser.on('-p', '--packages',
                'Attempt to install system package dependencies') do
        self.packages = true
      end
      parser.on('--skip-dependencies',
                "Don't install a module's dependencies") do
        self.skip_dependencies = true
      end

      parser.on_tail('-h', '--help', 'Show this message') do
        puts parser
        exit
      end
      # Another typical switch to print the version.
      parser.on_tail('-v', '--version', 'Show version') do
        puts VERSION
        exit
      end
    end

    ##
    # Parses the given arguments, stores them, and returns the options.
    def parse(args)
      @parser.parse!(args)
      self
    end

    ##
    # Prints the help message for the command line program.
    def print_help
      puts @parser
    end

    ##
    # Checks that all provided options are valid. Rasises an
    # +OptionsError+ when given invalid options.
    def validate
      if @packages && !@system
        raise OptionsError.new(
          'Must proved system when installing packages with --packages',
          self
        )
      end

      config = Configuration.instance
      if @system && !config.installers.key?(@system)
        raise OptionsError.new("Unknown system #{system}", self)
      end
    end
  end
end
