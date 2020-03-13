require 'optparse'

module Tildeconfig
  class OptionsParser
    attr_reader :parser, :options

    class Options
      attr_accessor :interactive

      def initialize
        self.interactive = true
      end

      def define_options(parser)
        parser.banner = "Usage: tildeconfig [options]"
        parser.separator ""
        parser.separator "Specific options:"

        parser.on("-n", "--non-interactive",
                  "Automatically accept prompts") do
          self.interactive = false
        end

        parser.separator ""
        parser.separator "Common options:"
        # No argument, shows at tail.  This will print an options summary.
        # Try it and see!
        parser.on_tail("-h", "--help", "Show this message") do
          puts parser
          exit
        end
        # Another typical switch to print the version.
        parser.on_tail("--version", "Show version") do
          puts VERSION
          exit
        end
      end
    end

    ##
    # Return a structure describing the options.
    #
    def parse(args)
      @options = Options.new
      @args = OptionParser.new do |parser|
        @options.define_options(parser)
        parser.parse!(args)
      end
      @options
    end
  end
end
