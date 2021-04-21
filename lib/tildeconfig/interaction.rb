require 'set'

module TildeConfig
  # Methods for interacting with the user.
  module Interaction
    class << self
      # Make a repeating prompt for y/n answer, with an empty answer defaulting
      # to no.
      # @param prompt [String] the prompt to display to the user
      # @param default_response [Boolean] the result to return if the
      #   user inputs the empty string
      # @param add_option_indicators [Boolean] if true, then appends
      #   either [yN] or [Yn] to the prompt dependening on the default
      #   response, preceded by a separating space
      # @return [Boolean] true if the user answered yes, false otherwise
      def ask_yes_no(prompt, default_response: false,
                     add_option_indicators: true)
        prompt += ' '
        if add_option_indicators
          prompt += default_response ? '[Yn] ' : '[yN] '
        end
        loop do
          print prompt
          res = $stdin.gets.chomp.downcase
          return default_response if res.strip.empty?
          return true if res.start_with?(/y/i)
          return false if res.start_with?(/n/i)

          puts "Please answer 'y' or 'n'."
        end
      end

      # Asks the user to select between the options in +options+. Starts by
      # printing +prompt+. Then, for each option in +options+, prints the option
      # with some prefix bracketed. The prefix is the string the user must enter
      # to select that option. Gets input from the user and if it starts with
      # one of the option prefixes, returns that option. If the user doesn't
      # enter valid input, repeatedly prompts them until they do.
      #
      # If +default_response+ is not nil, then it must equal one of the
      # +options+. Then in the prompt, that option will be capitalized and if
      # the user inputs an empty string, then +default_response+ will be
      # returned.
      # @param prompt [String] the prompt to print to the user
      # @param options [Array<String>] the list of options, all lowercase
      # @param default_response [String, nil] if not nil, the response that's
      #   returned when the user inputs an empty string
      # @return [String] the entire option the user selected
      def ask_with_options(prompt, options, default_response = nil)
        prompt, prefixes = options_prompt(prompt, options, default_response)
        loop do
          print prompt
          res = $stdin.gets.chomp
          selected = select_option(prefixes, default_response, res)
          return selected unless selected.nil?

          puts 'Please enter a valid response'
        end
      end

      # Returns the prompt to be displayed to the user starting with +prompt+
      # and containing options +options+. Computes the prefixes of each option
      # that need to be matched in order to select that option, and the prefix
      # appears bracketed in the option in the prompt. If +default_response+ is
      # not nil, then that option is capitalized in the prompt. Also returns the
      # map of prefixes
      # @param prompt [String] prompt which appears at the start of the result
      # @param options [Array<String>] the list of options to appear in the
      #   prompt
      # @param default_response [String, nil] the element of +options+ that
      #   should be selected if the user enters an empty input, or nil if
      #   there's no default option
      # @return [Array] the generated prompt and a map from prefixes to the
      #   option that would be selected by the prefix
      def options_prompt(prompt, options, default_response)
        result = prompt
        result << ' '
        prefixes = {}
        option_strings = []
        options.each do |option|
          prefix = shortest_unique_prefix(option, options)
          prefixes[prefix] = option
          option_string = if !default_response.nil? &&
                             option == default_response
                            "[#{prefix.capitalize}]"
                          else

                            "[#{prefix}]"
                          end
          option_string << option[prefix.size..]
          option_strings << option_string
        end
        result << option_strings.join(',')
        result << ': '
        [result, prefixes]
      end

      # Given a mapping of prefixes to options and an input, returns the option
      # for any prefx that +input+ matches or nil if no prefix matches.
      # If +default_response+ is not nil and +input+ is empty, returns
      # +default_response+. If one of the prefixes is equal to its option, which
      # will occur when one option is a prefix of another, then selecting that
      # option requires input to equal it exactly.
      # @param prefixes [Hash<String, String>] the prefix map from prefixes to
      #   the option of the prefix
      # @param default_response [String, nil] if not nil, then returns the
      #   default response on an empty input
      # @param input [String] the input to match prefixes against
      # @return [String] the option for the prefix +input+ matches, or nil if no
      #   prefix matches
      def select_option(prefixes, default_response, input)
        return default_response if !default_response.nil? && input.strip.empty?

        prefix_options = Set.new
        # rubocop:disable Style/CombinableLoops
        prefixes.each do |prefix, option|
          next unless prefix == option
          return option if input == option

          prefix_options << prefix
          prefix_options << prefix
        end
        prefixes.each do |prefix, option|
          next if prefix_options.include?(prefix)
          return option if input.start_with?(prefix)
        end
        # rubocop:enable Style/CombinableLoops
        nil
      end

      private

      # Finds the shortest prefix of option such that only option has it as a
      # prefix in options. If no such prefix exists, i.e. if option is a prefix
      # of some other option in options, then returns option itself.
      # @param option [String] an option string
      # @param optinos [Array<String>] array of options containing +option+
      # @return [String] the shortest prefix of option such that option is the
      #   unique element options that has the prefix, or +options+ if no such
      #   prefix exists
      def shortest_unique_prefix(option, options)
        (1..option.size).each do |i|
          prefix = option[0...i]
          has_prefix = options.select { |opt| opt.start_with?(prefix) }
          return prefix if has_prefix.size == 1
        end
        option
      end
    end
  end
end
