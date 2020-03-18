require 'tildeconfig'

include TildeConfig

describe ConfigurationChecks do
  it 'should validate a valid configuration' do
    Configuration.with_empty_configuration do
      mod :mod1 => [:mod2]
      mod :mod2

      config = Configuration.instance
      ConfigurationChecks.validate_dependency_references(config)
      ConfigurationChecks.validate_circular_dependencies(config)
    end
  end

  it 'should detect an invalid dependency reference' do
    Configuration.with_empty_configuration do
      mod :mod1 => [:mod2]

      config = Configuration.instance
      expect { ConfigurationChecks.validate_dependency_references(config) }
        .to raise_error(DependencyReferenceError)
    end
  end

  it 'should detect circular dependencies' do
    Configuration.with_empty_configuration do
      mod :mod1 => [:mod2]
      mod :mod2 => [:mod3]
      mod :mod3 => [:mod1]

      valid = []
      cycle = %i[mod1 mod2 mod3]
      cycle.size.times do
        valid << cycle.dup
        cycle.push(cycle.shift)
      end
      config = Configuration.instance
      expect { ConfigurationChecks.validate_circular_dependencies(config) }
        .to raise_error(CircularDependencyError) do |e|
        expect(valid.include?(e.cycle)).to be_truthy
      end
    end
  end
end
