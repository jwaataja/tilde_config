require 'tildeconfig'
require 'tmpdir'
require 'fileutils'

include TildeConfig

describe 'Running shell commands' do
  it 'should be able to run a simple command' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'shell_test_file')
      CLI.run(%w[install mod1], load_config_file: false) do
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
      CLI.run(%w[install mod1], load_config_file: false) do
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
      CLI.run(%w[install mod1], load_config_file: false) do
        mod :mod1 do |m|
          m.install do
            sh 'return 1'
          end

          m.install do
            sh "touch #{path}"
          end
        end
      end

      expect(File.exist?(path)).to be_falsey
    end
  end

  it 'should all commands regardless of errors --ignore-errors passed' do
    Dir.mktmpdir do |dir|
      path = File.join(dir, 'shell_test_file')
      CLI.run(%w[install mod1 --ignore-errors], load_config_file: false) do
        mod :mod1 do |m|
          m.install do
            sh 'return 1'
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
