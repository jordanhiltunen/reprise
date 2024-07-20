# frozen_string_literal: true

require_relative "lib/reprise/version"

Gem::Specification.new do |spec|
  spec.name = "reprise"
  spec.version = Reprise::VERSION
  spec.authors = ["Jordan Hiltunen"]
  spec.email = ["oss@jordanhiltunen.com"]

  spec.summary = "Fast recurring event generation for Ruby."
  spec.description = <<~DESCRIPTION.strip.gsub(/\s+/, " ")
    Generates date & time events from recurrence rules to support various calendar and scheduling use cases,
    with an emphasis on speed; the core of the Reprise gem is implemented as a Rust extension to enable its
    use for performance-sensitive workloads.
  DESCRIPTION
  spec.homepage = "https://github.com/jordanhiltunen/reprise"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "https://github.com/jordanhiltunen/reprise/blob/main/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]
  spec.extensions = %w[ext/reprise/extconf.rb]

  spec.add_development_dependency "benchmark-ips"
  spec.add_development_dependency "benchmark-memory"
  spec.add_development_dependency "bundler"
  spec.add_development_dependency "ice_cube"
  spec.add_development_dependency "memory_profiler"
  spec.add_development_dependency "montrose"
  spec.add_development_dependency "rake", "~> 13.2"
  spec.add_development_dependency "rake-compiler", "~> 1.2.0"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "yard"

  spec.add_dependency "activesupport", ">= 7.0.0"
  spec.add_dependency "rb_sys", ">= 0.9.86"
end
