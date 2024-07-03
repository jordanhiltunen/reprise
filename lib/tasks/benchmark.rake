# frozen_string_literal: true

require "coruscate"
require "active_support"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/time"
require "active_support/testing/time_helpers"
require "benchmark"
require "ice_cube"
require "benchmark/ips"
require "benchmark/memory"

desc "Run benchmarks"
task :benchmark do
  def generate_ice_cube_occurrences
    schedule = IceCube::Schedule.new(now = Time.current) do |s|
      s.add_recurrence_rule(IceCube::Rule.weekly(1, :tuesday).until(Date.today + 365))
      s.add_recurrence_rule(IceCube::Rule.weekly(1, :wednesday).until(Date.today + 365))
      s.add_exception_time(now + 1.day)
    end

    schedule.all_occurrences.size
  end

  def generate_coruscate_occurrences
    schedule = Coruscate::Schedule.new(
      starts_at: Time.current,
      ends_at: Time.current + 365.days,
      time_zone: "Hawaii"
    )

    schedule.repeat_weekly("tuesday", { hour: 1, minute: 2, second: 3 }, 300)
    schedule.repeat_weekly("wednesday", { hour: 1, minute: 2, second: 3 }, 300)
    schedule.add_exclusion(
      (Time.current.in_time_zone("Hawaii") - 30.minutes).to_i,
      (Time.current.in_time_zone("Hawaii") + 5.minutes).to_i
    )

    schedule.occurrences.size
  end

  pp "Benchmarking Iterations Per Second (IPS)"
  Benchmark.ips do |x|
    x.report("IceCube:") { generate_ice_cube_occurrences }
    x.report("Coruscate:") { generate_coruscate_occurrences }
  end

  pp "Benchmarking Memory Use"
  Benchmark.memory do |x|
    x.report("IceCube:") { generate_ice_cube_occurrences }
    x.report("Coruscate:") { generate_coruscate_occurrences }

    x.compare!
  end
end
