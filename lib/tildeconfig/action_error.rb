module TildeConfig
  ##
  # Represents an error that occurs when performing an action specified in a
  # configuration file.
  class ActionError < StandardError
    ##
    # Print out a summary to standard error indicating what failed.
    def print_warning
      warn message
    end

    ##
    # Executes the provided block. If an +ActionError+ is raised and
    # +options.should_ignore_errors+ is true, then prints an error to the user.
    # Otherwise, the error is raised as normal.
    def self.print_warn_if_no_ignore(options, &block)
      block.call
    rescue ActionError => e
      raise e unless options.should_ignore_errors

      e.print_warning
    end
  end
end
