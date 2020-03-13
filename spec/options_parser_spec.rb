require 'tildeconfig'
include Tildeconfig

describe OptionsParser do
  it "can parse empty options with correct defaults" do
    options = OptionsParser.new.parse([])
    expect(options.interactive).to be_truthy
  end

  it "can turn off interactivity" do
    options = OptionsParser.new.parse(%w{-n})
    expect(options.interactive).to be_falsey
    options = OptionsParser.new.parse(%w{--non-interactive})
    expect(options.interactive).to be_falsey
  end
end
