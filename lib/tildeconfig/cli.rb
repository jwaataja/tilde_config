module TildeConfig
  # Array of config file names to serach for, in order of priority with highest
  # priority first.
  CONFIG_FILES = %w[tildeconfig tildeconfig.rb].freeze

  ##
  # Methods for the tildeconfig command line interface.
  module CLI
    class << self
      ##
      # Starts the main execution of the command line program. The +args+ should
      # be the command line arguments to the program. Set +load_config_file+ to
      # false to prevent the default configuration file from being loaded. If a
      # block is provided, yields to it right after the configuration file would
      # be loaded but before the main program executes. This is so that a block
      # can serve as a "pseudo" configuration file. Returns true on success,
      # false on failure.
      def run(args, load_config_file: true)
        options = Options.new.parse(args)
        begin
          options.validate
        rescue OptionsError => e
          warn "Invalid options: #{e.message}"
          found_error = true
        end
        return false if found_error

        if args.empty?
          options.print_help
          return false
        end

        config_file = nil
        if load_config_file
          config_file, found = find_config_file(options)
          return false unless found
        end

        Configuration.with_standard_library do
          found_error = false
          begin
            load(config_file) if load_config_file
          rescue SyntaxError => e
            warn 'Syntax error while reading configuration file:'
            warn e.message
            found_error = true
          end
          return false if found_error

          yield if block_given?

          return false unless validate_configuration

          command = args[0]
          modules = args.drop(1).map(&:to_sym)
          modules.each do |m|
            unless Configuration.instance.modules.key?(m)
              warn "Unknown module #{m}"
              return false
            end
          end
          case command
          when 'install'
            install(modules, options)
          when 'uninstall'
            uninstall(options)
          when 'update'
            update(options)
          when 'refresh'
            refresh(modules, options)
          else
            puts "Unknown command #{command}"
            false
          end
        end
      end

      ##
      # Installs the given modules with the given options. If +modules+ is
      # empty then installs all modules. Returns true on success, false on
      # failure.
      def install(modules, options)
        config = Configuration.instance
        modules = config.modules.keys if modules.empty?
        graph = DependencyAlgorithms.build_dependency_graph(config)
        # This should succeed because the abscence of cycles should have been
        # validated.
        topo_sort = DependencyAlgorithms.topological_sort(graph)
        unless options.skip_dependencies
          modules = modules.flat_map { |m| config.modules[m].all_dependencies }
        end
        modules = topo_sort.select { |m| modules.include?(m) }
        modules.each do |name|
          m = Configuration.instance.modules[name]
          puts "Installing #{name}"
          succeeded = true
          begin
            m.execute_install(options)
          rescue FileInstallError => e
            warn "Error while installing module #{name}."
            warn "Failed to install file #{e.file.src} to #{e.file.dest}: " \
              "#{e.message}"
            succeeded = false
          rescue PackageInstallError => e
            warn "Error while installing module #{name}."
            warn e.message
            succeeded = false
          end
          return false unless succeeded
        end
        true
      end

      ##
      # Uninstalls all modules. Returns true on success, false on failure.
      def uninstall(options)
        Configuration.instance.modules.each do |name, m|
          puts "Uninstalling #{name}"
          m.execute_uninstall
        end
        true
      end

      ##
      # Updates all modules. Returns true on success, false on failure.
      def update(options)
        succeeded = true
        Configuration.instance.modules.each do |name, m|
          puts "Updating #{name}"
          begin
            succeeded = m.execute_update
          rescue FileInstallError => e
            warn "Error while updating module #{name}."
            warn "Failed to install file #{e.file.src} to #{e.file.dest}: " \
              "#{e.message}"
            succeeded = false
          end
          ereturn false unless succeeded
        end
        true
      end

      ##
      # Refreshs the files of all given modules. If +modules+ is empty, then
      # refreshes all modules.
      def refresh(modules, options)
        config = Configuration.instance
        modules = Configuration.instance.modules.keys if modules.empty?
        modules.each do |name|
          puts "Refreshing module #{name}"
          config.modules[name].execute_refresh
        end
        true
      end

      private

      ##
      # Finds the config file to use. Returns two files. The first is the config
      # file path or nil if there was no specified config file path and none was
      # found. The second is true if a config file was found and false if not.
      # If no config file was found then prints an error message.
      def find_config_file(options)
        if options.config_file.nil?
          search_default_config_files
        else
          unless File.exist?(options.config_file)
            warn "Failed to find config file #{options.config_file}"
            return options.config_file, false
          end
          [options.config_file, true]
        end
      end

      ##
      # Searches the default config files to find the first that exists. Returns
      # the config file and true if it exists, nil and false if none exist in
      # the current directory. If no config file was found, prints an error
      # message.
      def search_default_config_files
        CONFIG_FILES.each do |config_file|
          return config_file, true if File.exist?(config_file)
        end

        warn 'No config file found in current directory'
        [nil, false]
      end

      ##
      # Validates the current configuration. Returns true on success. Return
      # false and prints an error message on failure.
      def validate_configuration
        return false unless validate_dependency_references

        validate_circular_dependencies
      end

      ##
      # Validates that the dependencies in the current configuration reference
      # valid modules. Returns true if all are valid. Returns false and prints
      # an error message otherwise.
      def validate_dependency_references
        config = Configuration.instance
        found_error = false
        begin
          ConfigurationChecks.validate_dependency_references(config)
        rescue DependencyReferenceError => e
          warn 'Error in configuraiton file:'
          warn e.message
          found_error = false
        end
        !found_error
      end

      ##
      # Validates the abscence of circular dependencies in the current
      # configuration. Returns true if there are no cycles. Returns false and
      # prints an error message otherwise.
      def validate_circular_dependencies
        config = Configuration.instance
        found_error = false
        begin
          ConfigurationChecks.validate_circular_dependencies(config)
        rescue CircularDependencyError => e
          print_circular_dependency_error(e)
          found_error = false
        end
        !found_error
      end

      ##
      # Prints a helpful error message for a given +CircularDependencyError+
      # error.
      def print_circular_dependency_error(error)
        warn 'Error in configuration file:'
        warn error.message
        cycle = error.cycle
        cycle.each.with_index do |name, i|
          dep = cycle[(i + 1) % cycle.size]
          warn "\tmodule #{name} depends on #{dep}"
        end
      end
    end
  end
end
