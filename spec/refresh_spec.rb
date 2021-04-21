require 'tmpdir'

module TildeConfig
  RSpec.describe Refresh do
    it 'can update a single file' do
      Dir.mktmpdir do |dir|
        src_dir = File.join(dir, 'src')
        dest_dir = File.join(dir, 'dest')
        Dir.mkdir(src_dir)
        Dir.mkdir(dest_dir)
        src_file = File.join(src_dir, 'testfile')
        dest_file = File.join(dest_dir, 'testfile')
        File.write(src_file, 'contents from source')
        File.write(dest_file, 'contents from dest')
        m = TildeMod.new(:test_name)
        m.root_dir src_dir
        m.install_dir dest_dir
        m.file 'testfile'
        TildeConfigSpec.suppress_output do
          Refresh.refresh(m, should_prompt: false)
        end
        expect(File.read(src_file)).to eq('contents from dest')
        expect(FileUtils.compare_file(src_file, dest_file)).to be_truthy
      end
    end

    it "skips files that haven't been updated" do
      Dir.mktmpdir do |dir|
        src_dir = File.join(dir, 'src')
        dest_dir = File.join(dir, 'dest')
        Dir.mkdir(src_dir)
        Dir.mkdir(dest_dir)
        src_file = File.join(src_dir, 'testfile')
        dest_file = File.join(dest_dir, 'testfile')
        contents = 'the file contents'
        File.write(src_file, contents)
        File.write(dest_file, contents)
        m = TildeMod.new(:test_name)
        m.root_dir src_dir
        m.install_dir dest_dir
        m.file 'testfile'
        TildeConfigSpec.suppress_output do
          Refresh.refresh(m, should_prompt: false)
        end
        expect(File.read(src_file)).to eq(contents)
      end
    end

    it 'skips symlinked files' do
      Dir.mktmpdir do |dir|
        src_dir = File.join(dir, 'src')
        dest_dir = File.join(dir, 'dest')
        Dir.mkdir(src_dir)
        Dir.mkdir(dest_dir)
        src_file = File.join(src_dir, 'testfile')
        dest_file = File.join(dest_dir, 'testfile')
        contents = 'the file contents'
        File.write(src_file, contents)
        FileUtils.ln_s(File.expand_path(src_file), dest_file)
        m = TildeMod.new(:test_name)
        m.root_dir src_dir
        m.install_dir dest_dir
        m.file_sym 'testfile'
        TildeConfigSpec.suppress_output do
          Refresh.refresh(m, should_prompt: false)
        end
        expect(File.read(src_file)).to eq(contents)
      end
    end
  end
end
