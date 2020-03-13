require 'optparse'

module Tildeconfig
  ##
  # Stores the options for the current run of the program.
  class Options
    attr_accessor :interactive

    def initialize
      self.interactive = true
      @parser = OptionParser.new do |parser|
        define_options(parser)
      end
    end

    def define_options(parser)
      parser.banner = "Usage: tildeconfig command [options]"
      parser.separator ""
      parser.separator "options:"

      parser.on("-n", "--non-interactive",
                "Automatically accept prompts") do
        self.interactive = false
      end

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

  def self.parser
    options = Options.new
    options.define_options(parser)

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
end
