require 'tildeconfig/version'
require 'tildeconfig/tilde_file'
require 'tildeconfig/options_error'
require 'tildeconfig/action_error'
require 'tildeconfig/shell_error'
require 'tildeconfig/package_install_error'
require 'tildeconfig/dependency_reference_error'
require 'tildeconfig/circular_dependency_error'
require 'tildeconfig/syntax_error'
require 'tildeconfig/file_install_error'
require 'tildeconfig/file_install_utils'
require 'tildeconfig/tilde_mod'
require 'tildeconfig/dependency_algorithms'
require 'tildeconfig/options'
require 'tildeconfig/package_installer'
require 'tildeconfig/system_package'
require 'tildeconfig/configuration'
require 'tildeconfig/configuration_checks'
require 'tildeconfig/user_commands'
require 'tildeconfig/cli'
require 'tildeconfig/predefined_installers'
require 'tildeconfig/standard_library'

module TildeConfig
  class Error < StandardError; end
  # Your code goes here...
end
