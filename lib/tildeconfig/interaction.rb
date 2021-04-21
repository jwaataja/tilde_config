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
          res = $stdin.gets.chomp
          return default_response if res.strip.empty?
          return true if res.start_with?(/y/i)
          return false if res.start_with?(/n/i)

          puts "Please answer 'y' or 'n'."
        end
      end

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

      def ask_with_options(prompt, options, default_response = nil)
        prompt, prefixes = options_prompt(prompt, options, default_response)
        loop do
          print prompt
          res = $stdin.gets.chomp
          return default_response if !default.response.nil? && res.strip.empty?

          prefixes.each do |prefix, option|
            return option if res.start_with?(prefix)
          end

          puts 'Please enter a valid response'
        end
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
