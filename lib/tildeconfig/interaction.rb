module TildeMod
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
      def self.ask_yes_no(prompt, default_response: false,
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
    end
  end
end
