module TildeConfig
  RSpec.describe TildeMod do
    describe 'Installing files' do
      it 'can use one arg syntax' do
        test_install_one_arg(false)
      end

      it 'can use one arg syntarx with symlinks' do
        test_install_one_arg(true)
      end

      def test_install_one_arg(use_symlinks)
        m = TildeMod.new(:test_name)

        Dir.mktmpdir do |dir|
          src_dir = File.join(dir, 'source')
          dst_dir = File.join(dir, 'dest')
          src_file = File.join(src_dir, 'filea')
          dst_file = File.join(dst_dir, 'filea')
          Dir.mkdir(src_dir)
          Dir.mkdir(dst_dir)
          File.write(src_file, 'some contents')
          m.root_dir src_dir
          m.install_dir dst_dir
          if use_symlinks
            m.file_sym 'filea'
          else
            m.file 'filea'
          end
          TildeConfigSpec.suppress_output { m.execute_install(Options.new) }
          expect(FileUtils.compare_file(src_file, dst_file)).to be_truthy
        end
      end

      it 'can use two arg syntax' do
        test_install_two_arg(false)
      end

      it 'can use two arg syntax with symlinks' do
        test_install_two_arg(true)
      end

      def test_install_two_arg(use_symlinks)
        m = TildeMod.new(:test_name)

        Dir.mktmpdir do |dir|
          src_dir = File.join(dir, 'source')
          dst_dir = File.join(dir, 'dest')
          src_file = File.join(src_dir, 'filea')
          dst_file = File.join(dst_dir, 'fileb')
          Dir.mkdir(src_dir)
          Dir.mkdir(dst_dir)
          File.write(src_file, 'some other contents')
          m.root_dir src_dir
          m.install_dir dst_dir
          if use_symlinks
            m.file_sym 'filea', 'fileb'
          else
            m.file 'filea', 'fileb'
          end
          TildeConfigSpec.suppress_output { m.execute_install(Options.new) }
          expect(FileUtils.compare_file(src_file, dst_file)).to be_truthy
        end
      end

      it 'modifying symlinked files modifies both' do
        m = TildeMod.new(:test_name)

        Dir.mktmpdir do |dir|
          src_dir = File.join(dir, 'source')
          dst_dir = File.join(dir, 'dest')
          src_file = File.join(src_dir, 'filea')
          dst_file = File.join(dst_dir, 'filea')
          Dir.mkdir(src_dir)
          Dir.mkdir(dst_dir)
          FileUtils.touch(src_file)
          m.root_dir src_dir
          m.install_dir dst_dir
          m.file_sym 'filea'
          TildeConfigSpec.suppress_output { m.execute_install(Options.new) }
          File.write(src_file, 'written to source')
          expect(FileUtils.compare_file(src_file, dst_file)).to be_truthy
          File.write(dst_file, 'written to dest')
          expect(FileUtils.compare_file(src_file, dst_file)).to be_truthy
        end
      end

      it 'can install to absolute paths' do
        test_install_absolute_paths(false)
      end

      it 'can install to absolute paths with symlinks' do
        test_install_absolute_paths(true)
      end

      def test_install_absolute_paths(use_symlinks)
        m = TildeMod.new(:test)
        Dir.mktmpdir do |dir|
          src_dir = File.join(dir, 'src')
          src_path = File.join(src_dir, 'input')
          Dir.mkdir(src_dir)
          File.write(src_path, 'contents')
          dest_path = File.join(dir, 'output')
          m.root_dir src_dir
          if use_symlinks
            m.file_sym 'input', dest_path
          else
            m.file 'input', dest_path
          end
          TildeConfigSpec.suppress_output { m.execute_install(Options.new) }
          expect(FileUtils.compare_file(src_path, dest_path)).to be_truthy
        end
      end

      it 'can install a directory and merge by default' do
        test_install_directory_merge(false)
      end

      it 'can install a directory and merge by default with symlinks' do
        test_install_directory_merge(true)
      end

      def test_install_directory_merge(use_symlinks)
        Dir.mktmpdir do |dir|
          src_dir = File.join(dir, 'src_dir')
          src_subdir = File.join(src_dir, 'subdir')
          src_file1 = File.join(src_dir, 'file1')
          src_file2 = File.join(src_subdir, 'file2')
          Dir.mkdir(src_dir)
          Dir.mkdir(src_subdir)
          File.write(src_file1, 'contents1')
          File.write(src_file2, 'contents2')
          dest_dir = File.join(dir, 'dest_dir')
          FileUtils.mkdir(dest_dir)
          dest_subdir = File.join(dest_dir, 'subdir')
          dest_file1 = File.join(dest_dir, 'file1')
          dest_file2 = File.join(dest_subdir, 'file2')
          dest_file3 = File.join(dest_dir, 'file3')
          File.write(dest_file3, 'contents3')
          TildeConfigSpec.run(%w[install m]) do
            mod :m do |m|
              m.root_dir dir
              m.install_dir dir
              if use_symlinks
                m.directory_sym 'src_dir', 'dest_dir'
              else
                m.directory 'src_dir', 'dest_dir'
              end
            end
          end
          expect(FileUtils.compare_file(src_file1, dest_file1)).to be_truthy
          expect(FileUtils.compare_file(src_file2, dest_file2)).to be_truthy
          expect(File.exist?(dest_file3)).to be_truthy
        end
      end

      it 'can install a directory and use override option' do
        test_install_directory_override(false)
      end

      it 'can install a directory and use override option with symlinks' do
        test_install_directory_override(true)
      end

      def test_install_directory_override(use_symlinks)
        Dir.mktmpdir do |dir|
          src_dir = File.join(dir, 'src_dir')
          src_subdir = File.join(src_dir, 'subdir')
          src_file1 = File.join(src_dir, 'file1')
          src_file2 = File.join(src_subdir, 'file2')
          Dir.mkdir(src_dir)
          Dir.mkdir(src_subdir)
          File.write(src_file1, 'contents1')
          File.write(src_file2, 'contents2')
          dest_dir = File.join(dir, 'dest_dir')
          FileUtils.mkdir(dest_dir)
          dest_subdir = File.join(dest_dir, 'subdir')
          dest_file1 = File.join(dest_dir, 'file1')
          dest_file2 = File.join(dest_subdir, 'file2')
          dest_file3 = File.join(dest_dir, 'file3')
          File.write(dest_file3, 'contents3')
          TildeConfigSpec.run(%w[install m]) do
            mod :m do |m|
              m.root_dir dir
              m.install_dir dir
              if use_symlinks
                m.directory_sym 'src_dir', 'dest_dir'
              else
                m.directory 'src_dir', 'dest_dir'
              end
            end
          end
          expect(FileUtils.compare_file(src_file1, dest_file1)).to be_truthy
          expect(FileUtils.compare_file(src_file2, dest_file2)).to be_truthy
          expect(File.exist?(dest_file3)).to be_truthy
        end
      end

      it 'respects the --no-override option for regular files' do
        Dir.mktmpdir do |dir|
          src_path = File.join(dir, 'input')
          dest_path = File.join(dir, 'output')
          File.write(src_path, 'src contents')
          File.write(dest_path, 'dest contents')
          TildeConfigSpec.run(%w[install mod1 --no-override],
                              should_succeed: false) do
            mod :mod1 do |m|
              m.root_dir dir
              m.install_dir dir

              m.file 'input', 'output'
            end
          end

          expect(File.read(dest_path)).to eq('dest contents')
        end
      end

      it 'respects the --no-override option for directories' do
        Dir.mktmpdir do |dir|
          src_dir = File.join(dir, 'input')
          dest_dir = File.join(dir, 'output')
          FileUtils.mkdir(src_dir)
          FileUtils.mkdir(dest_dir)
          File.write(File.join(src_dir, 'file'), 'contents')
          TildeConfigSpec.run(%w[install mod1 --no-override],
                              should_succeed: false) do
            mod :mod1 do |m|
              m.root_dir dir
              m.install_dir dir
              m.directory 'input', 'output'
            end
          end

          expect(Dir.empty?(dest_dir)).to be_truthy
        end
      end
    end
  end
end
