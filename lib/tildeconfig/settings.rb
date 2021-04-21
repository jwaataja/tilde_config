module TildeConfig
  # The collection of setting values for a single run of tildeconfig.
  # Each setting is a property that can be accessed by calling the
  # accessor method with the same name as the setting.
  class Settings
    # @return [Hash<Symbol, Object>] the collection of possible settings for a
    #   +Settings+ object. Keys are symbols representing setting names
    #   and values are the initial values for those settings.
    @defined_settings = {}

    class << self
      attr_reader :defined_settings
    end

    # Defines a new setting for the +Settings+ class. Creates an
    # accessor with +name+. New instances of +Settings+ will have
    # +default_value+ as the initial value for the setting.
    # @param name [Symbol] the name of the setting
    # @param default_value [Object] the initial value of the setting
    def self.define_setting(name, default_value = nil)
      attr_accessor name

      @defined_settings[name] = default_value
    end

    # @return [String, nil] the command to use for viewing diffs between
    #   files. Should contain "%a" and "%b" which are substituted for
    #   the two file paths to diff.
    define_setting :diff_command, 'diff -u "%a" "%b" | less'

    # Constructs a new +Settings+, with all settings initialized to
    # their initial values. Any settings appearing as keys in
    # +initial_settings+ have their initial values set to their value in
    # the hash instead.
    # @param initial_settings [Hash<Symbol, Object>] map of setting
    #   names to values that override the initial values
    # @return [Settings] a new +Settings+
    def initialize(initial_settings = {})
      check_setting_names(initial_settings)
      self.class.defined_settings.each do |setting, default_value|
        value = default_value
        value = initial_settings[setting] if initial_settings.key?(setting)
        set_setting(setting, value)
      end
    end

    # Gets the current value of the setting with name +setting_name+
    # @param setting_name [Symbol] name of the setting
    # @return [Object] current value of the setting, or nil if it
    #   doesn't exist
    def get_setting(setting_name)
      return nil unless self.class.defined_settings.key?(setting_name)

      instance_variable_get("@#{setting_name}")
    end

    def set_setting(setting_name, value)
      check_setting_name(setting_name)
      instance_variable_set("@#{setting_name}", value)
    end

    # For any settings with names appearing as keys in
    # +setting_values+, sets the their values to the value in the
    # mapping.
    # @param setting_values [Hash<Symbol, Object>] a mapping of setting
    #   names to the values to set.
    # rubocop:disable Naming/AccessorMethodName
    def set_settings(setting_values)
      check_setting_names(setting_values)
      setting_values.each do |setting, value|
        set_setting(setting, value)
      end
    end
    # rubocop:enable Naming/AccessorMethodName

    # Raises an error if +setting_name+ is not a valid setting.
    # @param setting_name [Symbol] setting name to check
    def check_setting_name(setting_name)
      return if self.class.defined_settings.key?(setting_name)

      raise "Invalid setting: #{setting_name}"
    end

    # Raises an error if any keys in +setting_values+ are not valid
    # settings.
    # @param setting_values [Hash<Symbol, Object>] map from symbols
    #   representing setting names to values
    def check_setting_names(setting_values)
      setting_values.each_key { |setting| check_setting_name(setting) }
    end
  end
end
