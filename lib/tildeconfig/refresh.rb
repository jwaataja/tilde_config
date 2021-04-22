module TildeConfig
  # Methods for refreshing modules. Refreshing a module means to check for
  # differences between the installed versions of files and the versions in the
  # local repository. For files that differ, it updates the local version to be
  # the same as the installed version. This is the opposite of the +update+
  # command.
  module Refresh
    class << self
      # Executes refresh action for +mod+. For each file that differs
      # between the installed version and version stored locally,
      # prompts the user for an action. They may copy the installed
      # version to the local repository, skip the file, or first view
      # the differences with the +diff_command+ setting.
      # @param mod [TildeMod] the module to refresh
      # @param should_prompt [Boolean] if true, ask the user before updating a
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
          elsif File.directory?(dest)
            refresh_directory(src, dest, should_prompt)
          else
            puts "Warning: unknown filetype #{src}"
          end
        end
      end

      private

      # Refreshes a regular file.
      # @param src [String] path to source file
      # @param dest [String] path to dest file
      # @param should_prompt [Boolean] if true, ask the user before updating a
      #   file in the local repository
      def refresh_file(src, dest, should_prompt)
        return unless check_dest_exists(dest)

        unless File.file?(dest)
          puts "Warning: #{dest} is not a regular file, skipping"
          return
        end

        return if FileUtils.compare_file(src, dest)

        puts "Installed file #{dest} differed from local version #{src}"
        loop do
          actions = {
            copy: 'copy to local respository',
            skip: 'skip it',
            diff: 'view differences'
          }
          response = actions[:copy]
          if should_prompt
            response = Interaction.ask_with_options(
              'What would you like to do?',
              [actions[:copy], actions[:skip], actions[:diff]],
              actions[:skip]
            )
          end

          case response
          when actions[:copy]
            puts "Copying #{dest} to #{src}"
            FileUtils.cp(dest, src)
            return
          when actions[:diff]
            view_file_diff(src, dest)
          when actions[:skip]
            return
          end
        end
      end

      # Shows the difference between +src+ and +dest+ using the
      # +diff_command+ setting.
      # @param src [String] source file
      # @param dest [String] destination file
      def view_file_diff(src, dest)
        if settings.diff_command.nil?
          puts "'diff_command' setting not set"
          return
        end

        command = settings.diff_command
                          .gsub(/%a/, src)
                          .gsub(/%b/, dest)
        system(command)
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

      # Refreshes a directory, recursively. Refreshes any files that
      # differ between the two directories. For any file in +dest+ that
      # doesn't exist in +src+, copies the version in dest into src.
      # @param src [String] the source directory
      # @param dest [String] the destination directory
      # @param should_prompt [Boolean] if true, ask the user before updating a
      #   file in the local repository
      def refresh_directory(src, dest, should_prompt)
        return unless check_dest_exists(dest)

        unless File.directory?(dest)
          puts "Warning: #{dest} is not a directory, skipping"
          return
        end

        src_entries = Dir.entries(src).sort
        dest_entries = Dir.entries(dest).sort
        src_entries.each do |entry|
          next if %w[. ..].include?(entry)

          src_path = File.join(src, entry)
          dest_path = File.join(dest, entry)
          next if File.symlink?(src_path)

          if File.file?(src_path)
            refresh_file(src_path, dest_path, should_prompt)
          elsif File.directory?(src_path)
            refresh_directory(src_path, dest_path, should_prompt)
          end
        end

        dest_entries.difference(src_entries).each do |entry|
          add_new_file(src, dest, entry, should_prompt)
        end
      end

      # Adds a new file from +dest_dir+ to +source_dir+ with name
      # +entry_name+.
      # @param src_dir [String] source directory
      # @param dest_dir [String] destination directory
      # @param entry_name [String] name of an entry in +dest_dir+
      # @param should_prompt [Boolean] if true, ask the user before updating a
      #   file in the local repository
      def add_new_file(src_dir, dest_dir, entry_name, should_prompt)
        if should_prompt && !Interaction.ask_yes_no(
          "New file #{entry_name} in directory " \
          "#{dest_dir}, copy into #{src_dir}? [y/N]"
        )
          return
        end

        FileUtils.cp_r(File.join(dest_dir, entry_name), src_dir)
      end
    end
  end
end
