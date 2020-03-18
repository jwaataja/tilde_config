module TildeConfig
  ##
  # An error representing the prescence of circular dependencies between
  # modules.
  class CircularDependencyError < StandardError
    attr_reader :cycle

    def initialize(message, cycle)
      super(message)
      @cycle = cycle
    end
  end
end
