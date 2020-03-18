require 'tildeconfig'
require 'tmpdir'

describe TildeConfig::TildeMod do
  it 'exists, and has basic methods' do
    m = TildeConfig::TildeMod.new(:test_name)
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
    m = TildeConfig::TildeMod.new(:test_name)
    m.file 'source'
    m.file 'source2', 'destination2'
    expect(m.files.size).to eq(2)
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

    m = TildeConfig::TildeMod.new(:test_name)
    m.my_method 1, 42
  end

  it 'Custom methods can use further methods' do
    def_cmd :my_method do |m|
      m.install do
        print 'no-op'
      end
    end

    m = TildeConfig::TildeMod.new(:test_name)
    expect(m).to receive(:install)
    m.my_method
  end

  describe 'Installing files' do
    it 'one-arg syntax works' do
      m = TildeConfig::TildeMod.new(:test_name)

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
        m.execute_install(TildeConfig::Options.new)
        expect(FileUtils.identical?(src_file, dst_file)).to be_truthy
      end
    end

    it 'two-arg syntax works' do
      m = TildeConfig::TildeMod.new(:test_name)

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
        m.execute_install(TildeConfig::Options.new)
        expect(FileUtils.identical?(src_file, dst_file)).to be(true)
      end
    end
  end

  describe 'all_dependencies' do
    it 'resolves basic dependencies' do
      b_installed = false
      CLI.run(%w[install a], load_config_file: false) do
        mod :a => [:b]
        mod :b do |m|
          m.install do
            b_installed = true
          end
        end
      end
      expect(b_installed).to be_truthy
    end
  end
end
