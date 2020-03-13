require 'tildeconfig'
include Tildeconfig

describe Options do
  it "can parse empty options with correct defaults" do
    options = Options.new.parse([])
    expect(options.interactive).to be_truthy
  end

  it "can turn off interactivity" do
    options = Options.new.parse(%w{-n})
    expect(options.interactive).to be_falsey
    options = Options.new.parse(%w{--non-interactive})
    expect(options.interactive).to be_falsey
  end
end
