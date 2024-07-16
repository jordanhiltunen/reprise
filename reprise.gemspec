# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "reprise/version"

Gem::Specification.new do |spec|
  spec.name          = "reprise"
  spec.version       = Reprise::VERSION
  spec.authors       = ["Jordan Hiltunen"]
  spec.email         = ["oss@jordanhiltunen.com"]

  spec.summary       = "Fast recurring event generation for Ruby."
  spec.description   = <<~DESCRIPTION.strip.gsub(/\s+/, " ")
    Generates date & time events from recurrence rules to support various calendar and scheduling use cases,
    with an emphasis on speed; the core of the Reprise gem is implemented as a Rust extension to enable its
    use for performance-sensitive workloads.
  DESCRIPTION
  spec.homepage      = "https://github.com/jordanhiltunen/reprise"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.2.0"

  # Prevent pushing this gem to RubyGems.org. To allow pushes either set the 'allowed_push_host'
  # to allow pushing to a single host or delete this section to allow pushing to any host.
  if spec.respond_to?(:metadata)
    spec.metadata["allowed_push_host"] = "TODO: Set to 'http://mygemserver.com'"

    spec.metadata["homepage_uri"] = spec.homepage
    spec.metadata["source_code_uri"] = "https://github.com/jordanhiltunen/reprise"
    spec.metadata["changelog_uri"] = "https://github.com/jordanhiltunen/reprise/blob/main/CHANGELOG.md"
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
  spec.extensions = %w[ext/reprise/extconf.rb]

  spec.add_development_dependency "benchmark-ips"
  spec.add_development_dependency "benchmark-memory"
  spec.add_development_dependency "bundler", "~> 2.5.9"
  spec.add_development_dependency "ice_cube"
  spec.add_development_dependency "memory_profiler"
  spec.add_development_dependency "montrose"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rake-compiler", "~> 1.2.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "yard"

  spec.add_dependency "activesupport", "~> 7.0.8"
  spec.add_dependency "rb_sys", ">= 0.9.86"
end