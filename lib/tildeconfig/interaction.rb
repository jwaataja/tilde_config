module TildeMod
  # Methods for interacting with the user.
  module Interaction
    class << self
      # Make a repeating prompt for y/n answer, with an empty answer defaulting
      # to no.
      # @param prompt [String] the prompt to display to the user
      # @return [Boolean] true if the user answered yes, false otherwise
      def self.ask_yes_no(prompt)
        loop do
          print prompt
          res = $stdin.gets.chomp
          return true if res.start_with?(/y/i)
          return false if res.start_with?(/n/i) || res.strip.empty?

          puts "Please answer 'y' or 'n'."
        end
      end
    end
  end
end
