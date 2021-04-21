module TildeConfig
  # Methods for refreshing modules.
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
          unless File.file?(src)
            puts "Warning: #{src} is not a regular file"
            next
          end
          unless File.exist?(dest)
            puts "Warning: #{dest} does not exist, skipping"
            next
          end
          unless File.file?(dest)
            puts "Warning: #{dest} is not a regular file, skipping"
            next
          end
          next if FileUtils.compare_file(src, dest)

          proceed = !should_prompt || Interaction.ask_yes_no(
            "Update #{src} in repository from #{dest}? [y/N] "
          )
          if proceed
            puts "Copying #{dest} to #{src}"
            FileUtils.cp(dest, src) if proceed
          end
        end
      end
    end
  end
end
