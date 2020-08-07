module TildeConfig
  RSpec.describe 'The mod command' do
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

    it 'should accept a hash as its argument to specify dependencies' do
      Configuration.with_standard_library do
        config = Configuration.instance
        mod :mod1 => [:mod2, :mod3]
        expect(config.modules[:mod1].dependencies).to eq(Set.new(%i[mod2 mod3]))
      end
    end

    it 'should raise an error if an invalid hash is given' do
      Configuration.with_standard_library do
        expect { mod :mod1 => :mod2, :mod3 => :mod4 }.to raise_error(
          TildeConfig::SyntaxError
        )
      end
    end
  end
end
