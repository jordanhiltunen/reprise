# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/testtask"
require "rake/extensiontask"

Rake.add_rakelib("lib/tasks")

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

task :dev do
  ENV["RB_SYS_CARGO_PROFILE"] = "dev"
end

platforms = [
  "x86_64-linux",
  "x86_64-linux-musl",
  "aarch64-linux",
  "x86_64-darwin",
  "arm64-darwin",
  "x64-mingw-ucrt",
  "x64-mingw32"
]

gemspec = Bundler.load_gemspec("coruscate.gemspec")
Rake::ExtensionTask.new("coruscate", gemspec) do |ext|
  ext.lib_dir = "lib/coruscate"
  ext.cross_compile = true
  ext.cross_platform = platforms
  ext.cross_compiling do |spec|
    spec.dependencies.reject! { |dep| dep.name == "rb_sys" }
    spec.files.reject! { |file| File.fnmatch?("ext/*", file, File::FNM_EXTGLOB) }
  end
end

task :remove_ext do
  path = "lib/coruscate/coruscate.bundle"
  File.unlink(path) if File.exist?(path)
end

Rake::Task["build"].enhance([:remove_ext])
