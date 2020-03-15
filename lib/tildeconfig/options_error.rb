module Tildeconfig
  class OptionsError < StandardError
    attr_reader :options

    def initialize(message, options)
      super(message)
      @options = options
    end
  end
end
