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

    it 'allows both types of file_sym invocations' do
      m = TildeMod.new(:test_name)
      m.file_sym 'source'
      m.file_sym 'source2', 'destination2'
      expect(m.files.size).to eq(2)
    end

    it 'can use file_glob with patterns' do
      test_file_glob_pattern(false)
    end

    it 'can use file_glob_sym with patterns' do
      test_file_glob_pattern(true)
    end

    def test_file_glob_pattern(use_symlinks)
      m = TildeMod.new(:test_name)
      Dir.mktmpdir do |dir|
        path1 = File.join(dir, 'file1')
        path2 = File.join(dir, 'file2')
        FileUtils.touch([path1, path2])
        m.root_dir dir
        m.install_dir File.join(dir, 'dest_dir')
        if use_symlinks
          m.file_glob_sym 'file*'
        else
          m.file_glob 'file*'
        end
        expect(m.files.size).to eq(2)
        m.files.each do |f|
          expect(f.src).to match(/\Afile[12]\Z/)
          expect(f.dest).to match(/\Afile[12]\Z/)
        end
      end
    end

    it 'expands glob patterns from the src_dir' do
      test_expand_glob_from_src_dir(false)
    end

    it 'expands glob patterns from the src_dir when using symlinks' do
      test_expand_glob_from_src_dir(true)
    end

    def test_expand_glob_from_src_dir(use_symlinks)
      Dir.mktmpdir do |dir|
        src_dir = File.join(dir, 'src_dir')
        FileUtils.mkdir(src_dir)
        path1 = File.join(src_dir, 'file1')
        path2 = File.join(src_dir, 'file2')
        FileUtils.touch([path1, path2])
        m.root_dir dir
        if use_symlinks
          m.file_glob_sym 'src_dir/file*'
        else
          m.file_glob 'src_dir/file*'
        end
        expect(m.files.size).to eq(2)
        m.files.each do |f|
          expect(f.src).to match(%r{\Asrc_dir/file[12]\Z})
          expect(f.dest).to match(%r{\Asrc_dir/file[12]\Z})
        end
      end
    end

    it 'installs glob files to the correct directory' do
      test_install_glob_to_correct_directory(false)
    end

    it 'installs glob files to the correct directory when using symlinks' do
      test_install_glob_to_correct_directory(true)
    end

    def test_install_glob_to_correct_directory(use_symlinks)
      Dir.mktmpdir do |dir|
        src_dir = File.join(dir, 'src_dir')
        FileUtils.mkdir(src_dir)
        path1 = File.join(src_dir, 'file1')
        path2 = File.join(src_dir, 'file2')
        FileUtils.touch([path1, path2])
        m.root_dir dir
        if use_symlinks
          m.file_glob_sym 'src_dir/file*', 'dest_dir'
        else
          m.file_glob 'src_dir/file*', 'dest_dir'
        end
        expect(m.files.size).to eq(2)
        m.files.each do |f|
          expect(f.dest).to match(%r{\Adest_dir/file[12]\Z})
        end
      end
    end

    it 'can use file_glob with a pattern that returns no results' do
      # TODO: Should this case be an error?
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
