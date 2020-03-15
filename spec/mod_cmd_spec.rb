require 'tildeconfig'

include Tildeconfig

describe 'The mod command' do
  it 'should define a module when passed nothing' do
    Configuration.with_standard_library do
      config = Configuration.instance
      mod :test_mod
      expect(config.modules).to have_key(:test_mod)
      m = config.modules[:test_mod]
      expect(m.name).to eq(:test_mod)
    end
  end

  it 'should yield to the provided block' do
    Configuration.with_standard_library do
      config = Configuration.instance
      was_run = false
      mod :test_mod do |_|
        was_run = true
      end
      expect(was_run).to be_truthy
      expect(config.modules).to have_key(:test_mod)
      m = config.modules[:test_mod]
      expect(m.name).to eq(:test_mod)
    end
  end
end
