module TildeConfig
  ##
  # Methods for installing files and directories.
  module FileInstallUtils
    class << self
      ##
      # Installs the file or directory at +src_path+ to +dest_path+. Raises a
      # +FileInstallError+ if the file at +src_path+ does not exist or if
      # there's an error while installing.
      def install(file_tuple, src_path, dest_path)
        ensure_install_directory_exists(file_tuple, dest_path)
        check_src_file_exists(file_tuple, src_path)

        if File.file?(src_path)
          install_file(file_tuple, src_path, dest_path)
        elsif File.directory?(src_path)
          install_directory(file_tuple, src_path, dest_path)
        end
      end

      private

      ##
      # Verifies that a file at +src_path+ exists. Raises a +FileInstallError+
      # if it does not.
      def check_src_file_exists(file_tuple, src_path)
        return if File.exist?(src_path)

        raise FileInstallError.new(
          "missing source file #{src_path}",
          file_tuple
        )
      end

      ##
      # Ensures that the directory for +dest_path+ exists. If the destination
      # directory already exists and is a file, raises a +FileInstallError+. If
      # it doesn't exist, attempt to create it.
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

      ##
      # Installs the regular file at +src_path+ to +dest_path+. Raises a
      # +FileInstallError+ if destination exists and is not a regular file.
      def install_file(file_tuple, src_path, dest_path)
        if File.exist?(dest_path) && !File.file?(dest_path)
          raise FileInstallError.new(
            "can't install file #{src_path}, destination exists and is a " \
            'directory',
            file_tuple
          )
        end
        puts "Copying #{src_path} to #{dest_path}"
        FileUtils.cp(src_path, dest_path)
      end

      ##
      # Installs the directory at +src_path+ to +dest_path+. Raises a
      # +FileInstallError+ if the destination exists and is not a directory.
      def install_directory(file_tuple, src_path, dest_path)
        unless File.exist?(dest_path)
          FileUtils.cp_r(src_path, dest_path)
          return
        end

        check_dest_is_directory(file_tuple, src_path, dest_path)
        merge_directories(file_tuple, src_path, dest_path)
      end

      ##
      # Verifies that +dest_path+ is a directory. If not, raises a
      # +FileInstallError+.
      def check_dest_is_directory(file_tuple, src_path, dest_path)
        return if File.directory?(dest_path)

        raise FileInstallError.new(
          "can't install directory #{src_path} to #{dest_path}, which is not " \
          'a directory',
          file_tuple
        )
      end

      ##
      # Installs all entries in the directory at +src_path+ to the directory at
      # +dest_path+. Raises a +FileInstallError+ if any entry fails to install.
      def merge_directories(file_tuple, src_path, dest_path)
        Dir.entries(src_path).each do |entry|
          next if %w[. ..].include?(entry)

          child_src_path = File.join(src_path, entry)
          child_dest_path = File.join(dest_path, entry)
          install(file_tuple, child_src_path, child_dest_path)
        end
      end
    end
  end
end
