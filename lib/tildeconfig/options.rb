require 'optparse'

module TildeConfig
  ##
  # Stores the options for the current run of the program.
  class Options
    attr_accessor :interactive, :system, :packages, :skip_dependencies,
                  :config_file, :should_ignore_errors, :should_override

    ##
    # Should be a symbol with either the value :override or :merge
    attr_accessor :directory_merge_strategy

    def initialize
      self.interactive = true
      self.system = nil
      self.packages = false
      self.skip_dependencies = false
      self.config_file = nil
      self.should_ignore_errors = false
      self.directory_merge_strategy = :merge
      self.should_override = true
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
      parser.on('--[no-]skip-dependencies',
                "Don't install a module's dependencies") do
        self.skip_dependencies = true
      end
      parser.on('-c', '--config-file CONFIG_FILE',
                'Load the given config file instead of the default') do |c|
        self.config_file = c
      end
      parser.on('-i',
                '--[no-]ignore-errors',
                'Don\'t stop execution if writing to a file or a '\
                'shell command fails') do |c|
        self.should_ignore_errors = c
      end
      parser.on(
        '-m',
        '--directory-merge-strategy STRATEGY',
        'Strategy for installing directories, should be either "override" or ' \
        '"merge". Default "override".'
      ) do |strategy|
        self.directory_merge_strategy = strategy.to_sym
      end
      parser.on('--[no-]override', 'Whether to override existing files') do |c|
        self.should_override = c
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

      if directory_merge_strategy != :override &&
         directory_merge_strategy != :merge
        raise OptionsError.new('The --directory-merge-strategy only accepts ' \
                               '"override" and "merge"', self)
      end
    end
  end
end
