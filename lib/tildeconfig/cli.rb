module Tildeconfig
  CONFIG_FILE_NAME = 'tildeconfig'

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
        if load_config_file && !File.exist?(CONFIG_FILE_NAME)
          warn "Failed to find config file #{CONFIG_FILE_NAME}"
          return false
        end

        Configuration.with_standard_library do
          found_error = false
          begin
            load(CONFIG_FILE_NAME) if load_config_file
          rescue SyntaxError => e
            warn 'Syntax error while reading configuration file:'
            warn e.message
            found_error = true
          end
          return false if found_error

          yield if block_given?

          return false unless validate_configuration

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
          else
            puts "Unknown command #{command}"
            false
          end
        end
      end

      def install(modules, options)
        modules = Configuration.instance.modules.each_key if modules.empty?
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

      def uninstall(options)
        Configuration.instance.modules.each do |name, m|
          puts "Uninstalling #{name}"
          m.execute_uninstall
        end
      end

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

      private

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
