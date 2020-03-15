require "tildeconfig"

include Tildeconfig

describe PackageInstaller do
  it "should call the block given to the constructor correctly" do
    arg = nil
    installer = PackageInstaller.new { |packages| arg = packages }
    expected = ["a", "b"]
    installer.install(expected)
    expect(arg).to eq(expected)
  end
end
