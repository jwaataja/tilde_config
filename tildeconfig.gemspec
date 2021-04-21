
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "tildeconfig/version"

Gem::Specification.new do |spec|
  spec.name          = "tildeconfig"
  spec.version       = TildeConfig::VERSION
  spec.authors       = ["Jason Waataja", "David Ross"]
  spec.email         = ["jwaataja@cs.washington.edu", "daboross@daboross.net"]

  spec.summary       = %q{DSL for managing user space configuration settings}
  spec.homepage      = "https://github.com/jwaataja/tilde.config"
  spec.license       = "MIT"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 2.1"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "rspec", "~>3.9"
  spec.add_development_dependency "rubocop"
  # For some reason, if did_you_mean and json aren't installed, then many
  # programs won't work with bundle exec on my machine.
  spec.add_development_dependency "did_you_mean"
  spec.add_development_dependency "json"
  spec.add_development_dependency "solargraph"
  spec.add_development_dependency "yard"
end
