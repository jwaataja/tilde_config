require "tildeconfig"

include Tildeconfig

describe SystemPackage do
  it "should remember its system names correctly" do
    name = "test name"
    package = SystemPackage.new(name, "a" => "1", "b" => "2")
    expect(package.name).to eq(name)
    expect(package.on_system?("a")).to be_truthy
    expect(package.on_system?("b")).to be_truthy
    expect(package.on_system?("c")).to be_falsey
    expect(package.name_for_system("a")).to eq("1")
    expect(package.name_for_system("b")).to eq("2")
    expect(package.name_for_system("c")).to be_nil
  end
end
