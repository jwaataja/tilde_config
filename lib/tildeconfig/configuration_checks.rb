module Tildeconfig
  ##
  # Methods that validate whether a given configuration is valid.
  module ConfigurationChecks
    class << self
      ##
      # Validates that all dependencies reference valid modules. Raises
      # a +DependencyReferenceError+ if an invalid reference is found.
      def validate_dependency_references(config)
        config.modules.each do |name, m|
          m.dependencies.each do |dep|
            unless config.modules.key?(dep)
              raise DependencyReferenceError, "module #{name} depends on " \
                "#{dep} which is not a module"
            end
          end
        end
      end

      ##
      # Validates that there are no circular dependencies in the given
      # configuration. Raises a +CircularDependencyError+ if a cycle in
      # dependencies is found.
      def validate_circular_dependencies(config)
        graph = build_dependency_graph(config)
        cycle = DependencyAlgorithms.find_cycle(graph)
        return if cycle.nil?

        raise CircularDependencyError.new('Circular dependency detected',
                                          cycle.reverse)
      end

      private

      ##
      # Returns the dependency graph for +config+ in the format expected
      # by +DependencyAlgorithms.topological_sort+. Specifically, if
      # module v depends on module u then the result has an edge (u, v)
      # because u must be installed before v.
      def build_dependency_graph(config)
        graph = {}
        config.modules.each_key { |name| graph[name] = [] }
        config.modules.each do |name, m|
          m.dependencies.each { |dep| graph[dep] << name }
        end
        graph
      end
    end
  end
end
