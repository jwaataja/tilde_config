require 'tildeconfig'

module TildeConfig
  describe PackageInstaller do
    it 'should call the block given to the constructor correctly' do
      arg = nil
      installer = PackageInstaller.new { |packages| arg = packages }
      expected = %w[a b]
      installer.install(expected)
      expect(arg).to eq(expected)
    end
  end
end
