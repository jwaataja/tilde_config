require 'tmpdir'

module TildeConfig
  RSpec.describe FileInstallUtils do
    it 'can install regular files' do
      Dir.mktmpdir do |dir|
        src_path = File.join(dir, 'input')
        dest_path = File.join(dir, 'output')
        File.write(src_path, 'test contents')
        TildeConfigSpec.suppress_output do
          FileInstallUtils.install(TildeFile.new(src_path, dest_path), src_path,
                                   dest_path)
        end
        expect(File.exist?(dest_path)).to be_truthy
        expect(FileUtils.compare_file(src_path, dest_path)).to be_truthy
      end
    end

    it 'raises an error when src does not exist' do
      Dir.mktmpdir do |dir|
        src_path = File.join(dir, 'input')
        dest_path = File.join(dir, 'output')
        expect do
          FileInstallUtils.install(TildeFile.new(src_path, dest_path), src_path,
                                   dest_path)
        end.to raise_error(FileInstallError)
      end
    end

    it 'creates nested directories when necessary' do
      Dir.mktmpdir do |dir|
        src_path = File.join(dir, 'src_dir', 'input')
        dest_path = File.join(dir, 'dest_dir', 'output')
        FileUtils.mkdir(File.join(dir, 'src_dir'))
        File.write(src_path, 'test contents')
        TildeConfigSpec.suppress_output do
          FileInstallUtils.install(TildeFile.new(src_path, dest_path), src_path,
                                   dest_path)
        end
        expect(File.exist?(dest_path)).to be_truthy
        expect(FileUtils.compare_file(src_path, dest_path)).to be_truthy
      end
    end

    it 'can install a directory to a location that does not yet exist' do
      Dir.mktmpdir do |dir|
        src_dir = File.join(dir, 'src_dir')
        FileUtils.mkdir(src_dir)
        src_file1 = File.join(src_dir, 'file1')
        src_file2 = File.join(src_dir, 'file2')
        File.write(src_file1, 'first contents')
        File.write(src_file2, 'second contents')
        dest_dir = File.join(dir, 'dest_dir')
        dest_file1 = File.join(dest_dir, 'file1')
        dest_file2 = File.join(dest_dir, 'file2')
        TildeConfigSpec.suppress_output do
          FileInstallUtils.install(TildeFile.new(src_dir, dest_dir), src_dir,
                                   dest_dir)
        end
        expect(FileUtils.compare_file(src_file1, dest_file1)).to be_truthy
        expect(FileUtils.compare_file(src_file2, dest_file2)).to be_truthy
      end
    end

    it 'can recursively merge a directory' do
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
        TildeConfigSpec.suppress_output do
          FileInstallUtils.install(TildeFile.new(src_dir, dest_dir), src_dir,
                                   dest_dir, merge_strategy: :merge)
        end
        expect(FileUtils.compare_file(src_file1, dest_file1)).to be_truthy
        expect(FileUtils.compare_file(src_file2, dest_file2)).to be_truthy
        expect(File.exist?(dest_file3)).to be_truthy
      end
    end

    it 'overrides directories when override merge strategy specified' do
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
        TildeConfigSpec.suppress_output do
          FileInstallUtils.install(TildeFile.new(src_dir, dest_dir), src_dir,
                                   dest_dir, merge_strategy: :override)
        end
        expect(FileUtils.compare_file(src_file1, dest_file1)).to be_truthy
        expect(FileUtils.compare_file(src_file2, dest_file2)).to be_truthy
        expect(File.exist?(dest_file3)).to be_falsey
      end
    end

    it "raises an error when installing into a directory that's a file" do
      Dir.mktmpdir do |dir|
        dest_dir = File.join(dir, 'dest_dir')
        File.write(dest_dir, 'regular file')
        src_path = File.join(dir, 'input')
        File.write(src_path, 'contents')
        dest_path = File.join(dest_dir, 'output')
        expect do
          FileInstallUtils.install(TildeFile.new(src_path, dest_path), src_path,
                                   dest_path)
        end.to raise_error(FileInstallError)
      end
    end

    it 'raises an error when installing a file to a non-file location' do
      Dir.mktmpdir do |dir|
        src_path = File.join(dir, 'input')
        dest_path = File.join(dir, 'output')
        File.write(src_path, 'contents')
        FileUtils.mkdir(dest_path)
        expect do
          FileInstallUtils.install(TildeFile.new(src_path, dest_path), src_path,
                                   dest_path)
        end.to raise_error(FileInstallError)
      end
    end

    it 'raises an error when installing a directory to non-directory ' \
        'location' do
      Dir.mktmpdir do |dir|
        src_path = File.join(dir, 'srcdir')
        dest_path = File.join(dir, 'destdir')
        FileUtils.mkdir(src_path)
        File.write(dest_path, 'regular file')
        expect do
          FileInstallUtils.install(TildeFile.new(src_path, dest_path), src_path,
                                   dest_path)
        end.to raise_error(FileInstallError)
      end
    end

    it 'doesn\'t install a regular file when --no-override specified' do
      Dir.mktmpdir do |dir|
        src_path = File.join(dir, 'input')
        dest_path = File.join(dir, 'output')
        File.write(src_path, 'test contents')
        File.write(dest_path, 'test contents')
        expect do
          FileInstallUtils.install(TildeFile.new(src_path, dest_path), src_path,
                                   dest_path, should_override: false)
        end.to raise_error(FileInstallError)
      end
    end

    it 'doesn\'t install a directory when --no-override specified' do
      Dir.mktmpdir do |dir|
        src_path = File.join(dir, 'input')
        dest_path = File.join(dir, 'output')
        FileUtils.mkdir(src_path)
        FileUtils.mkdir(dest_path)
        expect do
          FileInstallUtils.install(TildeFile.new(src_path, dest_path), src_path,
                                   dest_path, should_override: false)
        end.to raise_error(FileInstallError)
      end
    end

    it 'applies --no-override to elements of a directory when merging' do
      Dir.mktmpdir do |dir|
        src_dir = File.join(dir, 'input')
        dest_dir = File.join(dir, 'output')
        src_path = File.join(src_dir, 'file')
        dest_path = File.join(src_dir, 'file')
        FileUtils.mkdir(src_dir)
        FileUtils.mkdir(dest_dir)
        File.write(src_path, 'test contents')
        File.write(dest_path, 'test contents')
        expect do
          FileInstallUtils.install(TildeFile.new(src_dir, dest_dir), src_dir,
                                   dest_dir,
                                   merge_strategy: :merge,
                                   should_override: false)
        end.to raise_error(FileInstallError)
      end
    end
  end
end
