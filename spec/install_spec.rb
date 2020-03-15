require 'tildeconfig'

include Tildeconfig

describe 'The install command line function' do
  it 'should run install actions' do
    install1_called = false
    install2_called = false
    install3_called = false
    CLI.run(%w[install], load_config_file: false) do
      mod :mod1 do |m|
        m.install do
          install1_called = true
        end
      end

      mod :mod2 do |m|
        m.install do
          install2_called = true
        end
        m.install do
          install3_called = true
        end
      end
    end

    expect(install1_called).to be_truthy
    expect(install2_called).to be_truthy
    expect(install3_called).to be_truthy
  end

  it 'should only install the specified modules' do
    install1_called = false
    install2_called = false
    install3_called = false
    CLI.run(%w[install mod1 mod3], load_config_file: false) do
      mod :mod1 do |m|
        m.install do
          install1_called = true
        end
      end

      mod :mod2 do |m|
        m.install do
          install2_called = true
        end
      end

      mod :mod3 do |m|
        m.install do
          install3_called = true
        end
      end
    end

    expect(install1_called).to be_truthy
    expect(install2_called).to be_falsey
    expect(install3_called).to be_truthy
  end
end
