module TildeConfig
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
        graph = DependencyAlgorithms.build_dependency_graph(config)
        cycle = DependencyAlgorithms.find_cycle(graph)
        return if cycle.nil?

        raise CircularDependencyError.new('circular dependency detected',
                                          cycle.reverse)
      end
    end
  end
end
