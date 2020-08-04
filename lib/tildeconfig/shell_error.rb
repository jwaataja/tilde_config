module TildeConfig
  ##
  # Erorr when a shell command fails, either because a command could not be
  # found or a command returned a non-zero exit status.
  class ShellError < ActionError
    attr_reader :command
    attr_reader :is_command_not_found
    attr_reader :exit_status

    def initialize(message, command, is_command_not_found, exit_status: 0)
      super(message)
      @command = command
      @is_command_not_found = is_command_not_found
      @exit_status = exit_status
    end
  end
end
