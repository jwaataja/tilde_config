module TildeConfig
  # Methods for refreshing modules. Refreshing a module means to check for
  # differences between the installed versions of files and the versions in the
  # local repository. For files that differ, it updates the local version to be
  # the same as the installed version. This is the opposite of the +update+
  # command.
  module Refresh
    class << self
      # Executes refresh action for this module. For each file that differs
      # between the installed version and version stored locally, asks the user
      # if they want to update the locally stored version and copies it if the
      # user says "yes".
      # @param mod [TildeMod] the module to refresh
      # @pararm should_prompt [Boolean] if true, ask the user before updating a
      #   file in the local repository
      def refresh(mod, should_prompt: true)
        mod.files.each do |file|
          next if file.is_symlink

          src = mod.src_path(file)
          dest = mod.dest_path(file)
          unless File.exist?(src)
            puts "Warning: #{src} does not exist"
            next
          end
          if File.file?(src)
            refresh_file(src, dest, should_prompt)
          else
            puts "Warning: unknown filetype #{src}"
          end
        end
      end

      private

      # Refreshes a regular file.
      # @param src [String] path to source file
      # @param dest [String] path to dest file
      # @pararm should_prompt [Boolean] if true, ask the user before updating a
      #   file in the local repository
      def refresh_file(src, dest, should_prompt)
        return unless check_dest_exists(dest)

        unless File.file?(dest)
          puts "Warning: #{dest} is not a regular file, skipping"
          return
        end

        return if FileUtils.compare_file(src, dest)

        proceed = !should_prompt || Interaction.ask_yes_no(
          "Update #{src} in repository from #{dest}? [y/N] "
        )
        return unless proceed

        puts "Copying #{dest} to #{src}"
        FileUtils.cp(dest, src) if proceed
      end

      # Checks if +dest+ exists and prints a prompt if not.
      # @param dest [String] file to check
      # @return [String] true if +dest+ exists
      def check_dest_exists(dest)
        if File.exist?(dest)
          true
        else
          puts "Warning: #{dest} does not exist, skipping"
          false
        end
      end
    end
  end
end
