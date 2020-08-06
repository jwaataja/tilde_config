# Tests that installers and system packages works.

module TildeConfig
  describe 'Installing system packages' do
    it 'should be able to define installers' do
      Configuration.with_standard_library do
        config = Configuration.instance
        args = nil
        def_installer :my_installer do |packages|
          args = packages
        end
        expect(config.installers).to have_key(:my_installer)
        installer = config.installers[:my_installer]
        arr = %w[a b]
        installer.install(arr)
        expect(args).to eq(arr)
      end
    end

    it 'should be able to define packages' do
      Configuration.with_standard_library do
        config = Configuration.instance
        def_package 'my_package', :ubuntu => 'a', :my_installer => 'b'
        expect(config.system_packages).to have_key('my_package')
        package = config.system_packages['my_package']
        expect(package.on_system?(:ubuntu)).to be_truthy
        expect(package.on_system?(:my_installer)).to be_truthy
        expect(package.on_system?(:fake_installer)).to be_falsey
        expect(package.name_for_system(:ubuntu)).to eq('a')
        expect(package.name_for_system(:my_installer)).to eq('b')
      end
    end

    it 'should attempt to use package name if not defined' do
      Configuration.with_standard_library do
        config = Configuration.instance
        args = nil
        def_installer :my_installer do |packages|
          args = packages
        end
        mod :my_mod do |m|
          m.pkg_dep 'package1', 'package2'
        end
        m = config.modules[:my_mod]
        m.execute_install(Options.new.parse(%w[--packages --system my_installer]))
        expect(args).to eq(%w[package1 package2])
      end
    end

    it 'should attempt to use package name if defined but no installer' do
      Configuration.with_standard_library do
        config = Configuration.instance
        args = nil
        def_installer :my_installer do |packages|
          args = packages
        end
        def_package 'test_package'
        mod :my_mod do |m|
          m.pkg_dep 'test_package'
        end
        m = config.modules[:my_mod]
        m.execute_install(Options.new.parse(%w[--packages --system my_installer]))
        expect(args).to eq(%w[test_package])
      end
    end

    it 'should use def_package appropriately' do
      Configuration.with_standard_library do
        config = Configuration.instance
        args = nil
        def_installer :my_installer do |packages|
          args = packages
        end
        def_package 'test_package', :my_installer => 'other_name'
        mod :my_mod do |m|
          m.pkg_dep 'test_package'
        end
        m = config.modules[:my_mod]
        m.execute_install(Options.new.parse(%w[--packages --system my_installer]))
        expect(args).to eq(%w[other_name])
      end
    end
  end
end
