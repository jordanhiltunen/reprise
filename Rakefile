# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rake/testtask"
require "rake/extensiontask"

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

Rake::ExtensionTask.new("coruscate") do |c|
  c.lib_dir = "lib/coruscate"
end

task :dev do
  ENV["RB_SYS_CARGO_PROFILE"] = "dev"
end
