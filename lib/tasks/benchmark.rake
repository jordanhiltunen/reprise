# frozen_string_literal: true

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
    require "coruscate"

    ice_cube_schedule = IceCube::Schedule.new(now = Time.current) do |s|
      s.add_recurrence_rule(IceCube::Rule.weekly(1, :monday).until(Date.today + 365))
      s.add_recurrence_rule(IceCube::Rule.weekly(1, :tuesday).until(Date.today + 365))
      s.add_recurrence_rule(IceCube::Rule.weekly(1, :wednesday).until(Date.today + 365))
      s.add_recurrence_rule(IceCube::Rule.weekly(1, :thursday).until(Date.today + 365))
      s.add_recurrence_rule(IceCube::Rule.weekly(1, :friday).until(Date.today + 365))
      s.add_exception_time(now + 1.day)
      s.add_exception_time(now + 2.days)
      s.add_exception_time(now + 3.days)
      s.add_exception_time(now + 4.days)
      s.add_exception_time(now + 5.days)
    end

  def generate_ice_cube_occurrences(ice_cube_schedule)
    ice_cube_schedule.all_occurrences.size
  end

    schedule = Coruscate::Schedule.new(
      starts_at: Time.current,
      ends_at: Time.current + 365.days,
      time_zone: "Hawaii"
    )

    schedule.repeat_weekly(:monday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
    schedule.repeat_weekly(:tuesday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
    schedule.repeat_weekly(:wednesday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
    schedule.repeat_weekly(:thursday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
    schedule.repeat_weekly(:friday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
    schedule.add_exclusion(
      starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") - 30.minutes).to_i,
      ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 5.minutes).to_i
    )
    schedule.add_exclusion(
      starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 2.days - 30.minutes).to_i,
      ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 2.days + 5.minutes).to_i
    )
    schedule.add_exclusion(
      starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 3.days - 30.minutes).to_i,
      ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 3.days + 5.minutes).to_i
    )
    schedule.add_exclusion(
      starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 4.days - 30.minutes).to_i,
      ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 4.days + 5.minutes).to_i
    )
    schedule.add_exclusion(
      starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 5.days - 30.minutes).to_i,
      ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 5.days + 5.minutes).to_i
    )

  def generate_coruscate_occurrences(schedule)
    schedule.occurrences.size
  end

  pp "Benchmarking Iterations Per Second (IPS)"
  Benchmark.ips do |x|
    x.report("IceCube:") { generate_ice_cube_occurrences(ice_cube_schedule) }
    x.report("Coruscate:") { generate_coruscate_occurrences(schedule) }
  end

  pp "Benchmarking Memory Use"
  Benchmark.memory do |x|
    x.report("IceCube:") { generate_ice_cube_occurrences(ice_cube_schedule) }
    x.report("Coruscate:") { generate_coruscate_occurrences(schedule) }

    x.compare!
  end
end
