module TildeConfig
  RSpec.describe Settings do
    before(:all) do
      Settings.define_setting :test_setting
      Settings.define_setting :with_default, 'default value'
    end

    it 'initializes settings correctly' do
      Configuration.with_empty_configuration do
        expect(settings.test_setting).to be_nil
        expect(settings.with_default).to eq('default value')
      end
    end

    it 'can set settings correctly' do
      Configuration.with_empty_configuration do
        settings.test_setting = 'a'
        settings.with_default = 'b'
        expect(settings.test_setting).to eq('a')
        expect(settings.with_default).to eq('b')
      end
    end

    it 'can specify initial values' do
      Configuration.with_empty_configuration(
        { test_setting: 'a', with_default: 'b' }
      ) do
        expect(settings.test_setting).to eq('a')
        expect(settings.with_default).to eq('b')
      end
    end

    it 'can get get settings with get_setting' do
      Configuration.with_empty_configuration do
        expect(settings.get_setting(:test_setting)).to be_nil
        expect(settings.get_setting(:with_default)).to eq('default value')
      end
    end

    it 'can set settings with set_setting' do
      Configuration.with_empty_configuration do
        settings.set_setting(:test_setting, 'a')
        settings.set_setting(:with_default, 'b')
        expect(settings.get_setting(:test_setting)).to eq('a')
        expect(settings.get_setting(:with_default)).to eq('b')
      end
    end
  end
end
