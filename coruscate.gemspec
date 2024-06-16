
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "coruscate/version"

Gem::Specification.new do |spec|
  spec.name          = "coruscate"
  spec.version       = Coruscate::VERSION
  spec.authors       = ["Jordan Hiltunen"]
  spec.email         = ["hello@jordanhiltunen.com"]

  spec.summary       = %q{A recurring event generation gem, implemented in Rust with an emphasis on performance}
  spec.homepage      = "https://github.com/jordanhiltunen/coruscate"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/jordanhiltunen/coruscate"
    spec.metadata["changelog_uri"] = "https://github.com/jordanhiltunen/coruscate/blob/main/CHANGELOG.md"
  else
    raise "RubyGems 2.0 or newer is required to protect against " \
      "public gem pushes."
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = %w[ext/coruscate/extconf.rb]

  spec.add_development_dependency "bundler", "~> 2.5.9"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-compiler", "~> 1.2.0"
  spec.add_development_dependency "rspec", "~> 3.0"

  spec.add_dependency "rb_sys", ">= 0.9.86"
end
