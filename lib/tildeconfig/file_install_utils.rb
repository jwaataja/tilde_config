module TildeConfig
  # Methods for installing files and directories.
  module FileInstallUtils
    class << self
      # Installs the file or directory at +src_path+ to +dest_path+. Raises a
      # +FileInstallError+ if the file at +src_path+ does not exist or if
      # there's an error while installing.
      #
      # The +merge_strategy+ should be a symbol that's either +:override+ or
      # +:merge+. The +:override+ value installs directories by writing over the
      # destination. The +:merge+ option recursively merges directories so that
      # the file structure of the src is spliced into the destination directory.
      # @param file_tuple [TildeFile] file to install
      # @param src_path [String] path to source of file to install from
      # @param dest_path [String] path to install file to
      # @param merge_strategy [Symbol] merge strategy to use, either +:merge+
      #   or +:override:+
      # @param should_override [Boolean] if true and a file already exists at
      #   +dest_path+, raises a +FileInstallError+
      def install(file_tuple, src_path, dest_path,
                  merge_strategy: :merge,
                  should_override: true)
        check_merge_strategy(merge_strategy)
        ensure_install_directory_exists(file_tuple, dest_path)
        check_src_file_exists(file_tuple, src_path)

        # When using symlinks, we don't ever want the source file to be
        # a relative path.
        src_path = File.expand_path(src_path) if file_tuple.is_symlink

        if File.file?(src_path)
          install_file(file_tuple, src_path, dest_path, should_override)
        elsif File.directory?(src_path)
          install_directory(file_tuple, src_path, dest_path, merge_strategy,
                            should_override)
        end
      end

      private

      # Verifies that a file at +src_path+ exists. Raises a +FileInstallError+
      # if it does not.
      # @param file_tuple [TildeFile] the +TildeFile+ to check
      # @param src_path [String] the actual path to check if it exists at
      def check_src_file_exists(file_tuple, src_path)
        return if File.exist?(src_path)

        raise FileInstallError.new(
          "missing source file #{src_path}",
          file_tuple
        )
      end

      # Ensures that the directory for +dest_path+ exists. If the destination
      # directory already exists and is a file, raises a +FileInstallError+. If
      # it doesn't exist, attempt to create it.
      # @param file_tuple [TildeFile] the +TildeFile+ to check
      # @param dest_path [String] the actual path to check if it exists at
      def ensure_install_directory_exists(file_tuple, dest_path)
        directory = File.dirname(dest_path)
        if File.exist?(directory) && !File.directory?(directory)
          raise FileInstallError.new(
            "can't install to non-directory #{directory}",
            file_tuple
          )
        end
        FileUtils.mkdir_p(directory)
      end

      # Installs the regular file at +src_path+ to +dest_path+. Raises a
      # +FileInstallError+ if destination exists and is not a regular file.
      # @param file_tuple [TildeFile] the file to install
      # @param src_path [String] path to source of file to install from
      # @param dest_path [String] path to install file to
      # @param should_override [Boolean] if true and a file already exists at
      #   +dest_path+, raises a +FileInstallError+
      def install_file(file_tuple, src_path, dest_path, should_override)
        if File.exist?(dest_path)
          unless File.file?(dest_path)
            raise FileInstallError.new(
              "can't install file #{src_path}, destination exists and is a " \
              'directory',
              file_tuple
            )
          end

          unless should_override
            raise FileInstallError.new(
              "can't install file #{src_path} to #{dest_path}, destination " \
              'exists and --no-override specified',
              file_tuple
            )
          end
        end
        puts "Copying #{src_path} to #{dest_path}"
        if file_tuple.is_symlink
          FileUtils.ln_sf(src_path, dest_path)
        else
          FileUtils.cp(src_path, dest_path)
        end
      end

      # Installs the directory at +src_path+ to +dest_path+. Raises a
      # +FileInstallError+ if the destination exists and is not a directory.
      # @param file_tuple [TildeFile] the file to install
      # @param src_path [String] path to source of file to install from
      # @param dest_path [String] path to install file to
      # @param merge_strategy [Symbol] merge strategy to use, either +:merge+
      #   or +:override:+
      # @param should_override [Boolean] if true and a file already exists at
      #   +dest_path+, raises a +FileInstallError+
      def install_directory(file_tuple, src_path, dest_path, merge_strategy,
                            should_override)
        check_merge_strategy(merge_strategy)
        if File.exist?(dest_path)
          check_dest_is_directory(file_tuple, src_path, dest_path)
          unless should_override
            raise FileInstallError.new(
              "can't install directory #{src_path} to #{dest_path}, " \
              'destination exists and --no-override specified',
              file_tuple
            )
          end

          if merge_strategy == :override
            FileUtils.rm_rf(dest_path)
          elsif file_tuple.is_symlink
            warn 'Installing directory as symlink, but destination directory ' \
                 'exists. Removing it.'
            FileUtils.rm_rf(dest_path)
          end
        end

        # We never merge directories if the directory is a symlink.
        if merge_strategy == :override || !File.exist?(dest_path) ||
           file_tuple.is_symlink
          if file_tuple.is_symlink
            FileUtils.ln_s(src_path, dest_path)
          else
            FileUtils.cp_r(src_path, dest_path)
          end
        else
          merge_directories(file_tuple, src_path, dest_path, merge_strategy,
                            should_override)
        end
      end

      # Verifies that +dest_path+ is a directory. If not, raises a
      # +FileInstallError+.
      # @param file_tuple [TildeFile] the +TildeFile+ to check
      # @param src_path [String] the source directory
      # @param dest_path [String] the actual path to check if it exists at
      def check_dest_is_directory(file_tuple, src_path, dest_path)
        return if File.directory?(dest_path)

        raise FileInstallError.new(
          "can't install directory #{src_path} to #{dest_path}, which is not " \
          'a directory',
          file_tuple
        )
      end

      # Installs all entries in the directory at +src_path+ to the directory at
      # +dest_path+. Raises a +FileInstallError+ if any entry fails to install.
      # @param file_tuple [TildeFile] file to install
      # @param src_path [String] path to source of file to install from
      # @param dest_path [String] path to install file to
      # @param merge_strategy [Symbol] merge strategy to use, either +:merge+
      #   or +:override:+
      # @param should_override [Boolean] if true and a file already exists at
      #   +dest_path+, raises a +FileInstallError+
      def merge_directories(file_tuple, src_path, dest_path, merge_strategy,
                            should_override)
        check_merge_strategy(merge_strategy)
        Dir.entries(src_path).each do |entry|
          next if %w[. ..].include?(entry)

          child_src_path = File.join(src_path, entry)
          child_dest_path = File.join(dest_path, entry)
          install(file_tuple, child_src_path, child_dest_path,
                  merge_strategy: merge_strategy,
                  should_override: should_override)
        end
      end

      # Verifies that +merge_strategy+ is either +:override+ or +:merge+. Raises
      # an error if not.
      # @param merge_strategy [Symbol] symbol to check
      def check_merge_strategy(merge_strategy)
        return unless merge_strategy != :override && merge_strategy != :merge

        raise StandardError, "Invalid merge strategy: #{merge_strategy}"
      end
    end
  end
end
