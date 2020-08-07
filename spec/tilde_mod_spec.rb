require 'tmpdir'
require 'fileutils'

module TildeConfig
  RSpec.describe TildeMod do
    # TODO: Change tests to use the subject.
    subject!(:m) { TildeMod.new(:test_name) }

    it 'exists, and has basic methods' do
      m = TildeMod.new(:test_name)
      m.install do
        print 'no-op'
      end
      m.uninstall do
        print 'no-op'
      end
      m.update do
        print 'no-op'
      end
      expect(m.install_cmds.length).to eq(1)
      expect(m.uninstall_cmds.length).to eq(1)
      expect(m.update_cmds.length).to eq(1)
    end

    it 'allows both types of file invocations' do
      m = TildeMod.new(:test_name)
      m.file 'source'
      m.file 'source2', 'destination2'
      expect(m.files.size).to eq(2)
    end

    it 'can use file_glob with patterns' do
      m = TildeMod.new(:test_name)
      Dir.mktmpdir do |dir|
        path1 = File.join(dir, 'file1')
        path2 = File.join(dir, 'file2')
        FileUtils.touch([path1, path2])
        m.file_glob "#{dir}/file*"
        expect(m.files.size).to eq(2)
      end
    end

    it 'can use file_glob with a pattern that returns no results' do
      m = TildeMod.new(:test_name)
      Dir.mktmpdir do |dir|
        m.file_glob "#{dir}/*"
        expect(m.files).to be_empty
      end
    end

    it 'can define custom methods' do
      # Surely a smarter way to do this?
      dummy = double('dummy')
      # This expectation just ensures our new function is called exactly once.
      expect(dummy).to receive(:method1)

      def_cmd :my_method do |_m, arg1, arg2|
        expect(arg1).to eq(1)
        expect(arg2).to eq(42)
        dummy.method1
      end

      m = TildeMod.new(:test_name)
      m.my_method 1, 42
    end

    it 'Custom methods can use further methods' do
      def_cmd :my_method do |m|
        m.install do
          print 'no-op'
        end
      end

      m = TildeMod.new(:test_name)
      expect(m).to receive(:install)
      m.my_method
    end

    describe 'Installing files' do
      it 'can use one arg syntax' do
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
          m.file 'filea'
          TildeConfigSpec.suppress_output { m.execute_install(Options.new) }
          expect(FileUtils.compare_file(src_file, dst_file)).to be_truthy
        end
      end

      it 'can use two arg syntax' do
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
          m.file 'filea', 'fileb'
          TildeConfigSpec.suppress_output { m.execute_install(Options.new) }
          expect(FileUtils.compare_file(src_file, dst_file)).to be_truthy
        end
      end

      it 'can install to absolute paths' do
        m = TildeMod.new(:test)
        Dir.mktmpdir do |dir|
          src_dir = File.join(dir, 'src')
          src_path = File.join(src_dir, 'input')
          Dir.mkdir(src_dir)
          File.write(src_path, 'contents')
          dest_path = File.join(dir, 'output')
          m.root_dir src_dir
          m.file 'input', dest_path
          TildeConfigSpec.suppress_output { m.execute_install(Options.new) }
          expect(FileUtils.compare_file(src_path, dest_path)).to be_truthy
        end
      end

      it 'can install a directory and merge by default' do
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
              m.directory 'src_dir', 'dest_dir'
            end
          end
          expect(FileUtils.compare_file(src_file1, dest_file1)).to be_truthy
          expect(FileUtils.compare_file(src_file2, dest_file2)).to be_truthy
          expect(File.exist?(dest_file3)).to be_truthy
        end
      end

      it 'can install a directory and use override option' do
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
              m.directory 'src_dir', 'dest_dir'
            end
          end
          expect(FileUtils.compare_file(src_file1, dest_file1)).to be_truthy
          expect(FileUtils.compare_file(src_file2, dest_file2)).to be_truthy
          expect(File.exist?(dest_file3)).to be_truthy
        end
      end
    end

    describe 'all_dependencies' do
      it 'resolves basic dependencies' do
        b_installed = false
        TildeConfigSpec.run(%w[install a]) do
          mod :a => [:b]
          mod :b do |m|
            m.install do
              b_installed = true
            end
          end
        end
        expect(b_installed).to be_truthy
      end

      it "doesn't run if --skip-dependencies used" do
        installed = false
        TildeConfigSpec.run(%w[install a --skip-dependencies]) do
          mod :a => [:b]
          mod :b do |m|
            m.install do
              installed = true
            end
          end
        end
        expect(installed).to be_falsey
      end

      it 'follows multiple levels' do
        Configuration.with_empty_configuration do
          mod :mod1 => [:mod2]
          mod :mod2 => [:mod3]
          mod :mod3
          mod :mod4
          config = Configuration.instance
          m = config.modules.fetch(:mod1)
          expect(m.all_dependencies.sort).to eq(%i[mod1 mod2 mod3])
        end
      end

      it 'works even with circular dependencies' do
        Configuration.with_empty_configuration do
          mod :mod1 => [:mod2]
          mod :mod2 => [:mod1]
          config = Configuration.instance
          m = config.modules.fetch(:mod1)
          expect(m.all_dependencies.sort).to eq(%i[mod1 mod2])
        end
      end
    end
  end
end
