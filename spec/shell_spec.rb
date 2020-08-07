require 'tmpdir'
require 'fileutils'

module TildeConfig
  RSpec.describe 'Running shell commands' do
    it 'should be able to run a simple command' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'shell_test_file')
        TildeConfigSpec.run(%w[install mod1]) do
          mod :mod1 do |m|
            m.install do
              sh "touch #{path}"
            end
          end
        end

        expect(File.exist?(path)).to be_truthy
      end
    end

    it 'should be able to run two commands' do
      Dir.mktmpdir do |dir|
        path1 = File.join(dir, 'file1')
        path2 = File.join(dir, 'file2')
        TildeConfigSpec.run(%w[install mod1]) do
          mod :mod1 do |m|
            m.install do
              sh <<~BASH
                touch #{path1}
                touch #{path2}
              BASH
            end
          end
        end

        expect(File.exist?(path1)).to be_truthy
        expect(File.exist?(path2)).to be_truthy
      end
    end

    it 'should not execute a second command if the first fails' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'shell_test_file')
        TildeConfigSpec.run(%w[install mod1]) do
          mod :mod1 do |m|
            m.install do
              sh 'false'
            end

            m.install do
              sh "touch #{path}"
            end
          end
        end

        expect(File.exist?(path)).to be_falsey
      end
    end

    it 'should run all commands if --ignore-errors passed' do
      Dir.mktmpdir do |dir|
        path = File.join(dir, 'shell_test_file')
        TildeConfigSpec.run(%w[install mod1 --ignore-errors]) do
          mod :mod1 do |m|
            m.install do
              sh 'false'
            end

            m.install do
              sh "touch #{path}"
            end
          end
        end

        expect(File.exist?(path)).to be_truthy
      end
    end
  end
end
