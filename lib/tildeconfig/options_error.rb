module Tildeconfig
  ##
  # An error indicating invalid options.
  class OptionsError < StandardError
    attr_reader :options

    def initialize(message, options)
      super(message)
      @options = options
    end
  end
end
