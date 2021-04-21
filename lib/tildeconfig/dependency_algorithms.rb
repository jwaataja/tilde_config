module TildeConfig
  ##
  # Graph algorithms for managing dependencies.
  # rubocop:disable Style/CombinableLoops
  module DependencyAlgorithms
    ##
    # Performs topological sort on the given graph, if possible. The
    # +graph+ is a hash where the keys are the nodes of the graph. The
    # values are sets or arrays of symbols representing the nodes that
    # node given by the key can reach with a single edge. If a
    # topolgoical sorts exists, then for all edges e = (u, v), vertec u
    # will occur bofer vertex v.
    #
    # Returns an array of symbols which represents the topological sort
    # if it was found, and nil otherwise.
    def self.topological_sort(graph)
      vertices = graph.keys
      counts = {}
      vertices.each { |v| counts[v] = 0 }
      vertices.each do |v|
        graph[v].each { |other| counts[other] += 1 }
      end

      q = Queue.new
      vertices.each { |v| q << v if counts[v].zero? }
      topo_sort = []
      until q.empty?
        vert = q.pop(true)
        topo_sort << vert
        graph[vert].each do |child|
          counts[child] -= 1
          q.push(child) if counts[child].zero?
        end
      end

      topo_sort.size == vertices.size ? topo_sort : nil
    end

    ##
    # Returns an array representing a cycle in graph if such a cycle
    # exists. Returns nil otherwise. The +graph+ is in the format as in
    # the +topological_sort+ method.
    def self.find_cycle(graph)
      vertices = graph.keys
      visited = {}
      on_stack = {}
      vertices.each do |v|
        visited[v] = false
        on_stack[v] = false
      end
      vertices.each do |v|
        next if visited[v]

        stack = []
        stack.push(v)
        visited[v] = true
        path = []
        until stack.empty?
          current = stack.pop
          if on_stack[current]
            on_stack[current] = false
            path.pop
            next
          end
          stack << current
          on_stack[current] = true
          path.push(current)
          graph[current].each do |child|
            if on_stack[child]
              index = path.find_index(child)
              return path.drop(index)
            end
            next if visited[child]

            stack.push(child)
            visited[child] = true
          end
        end
      end
      nil
    end

    ##
    # Returns the dependency graph for +config+ in the format expected
    # by +DependencyAlgorithms.topological_sort+. Specifically, if
    # module v depends on module u then the result has an edge (u, v)
    # because u must be installed before v.
    def self.build_dependency_graph(config)
      graph = {}
      config.modules.each_key { |name| graph[name] = [] }
      config.modules.each do |name, m|
        m.dependencies.each { |dep| graph[dep] << name }
      end
      graph
    end
  end
  # rubocop:enable Style/CombinableLoops
end
