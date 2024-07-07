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

  ice_cube_schedule = IceCube::Schedule.new(now = Time.current, end_time: Time.current + 365.days)
  ice_cube_schedule.add_recurrence_rule(IceCube::Rule.weekly(1).day(:monday).until(now + 1.year))
  ice_cube_schedule.add_recurrence_rule(IceCube::Rule.weekly(1).day(:tuesday).until(now + 1.year))
  ice_cube_schedule.add_recurrence_rule(IceCube::Rule.weekly(1).day(:wednesday).until(now + 1.year))
  ice_cube_schedule.add_recurrence_rule(IceCube::Rule.weekly(1).day(:thursday).until(now + 1.year))
  ice_cube_schedule.add_recurrence_rule(IceCube::Rule.weekly(1).day(:friday).until(now + 1.year))
  ice_cube_schedule.add_exception_time(now + 1.day)
  ice_cube_schedule.add_exception_time(now + 2.days)
  ice_cube_schedule.add_exception_time(now + 3.days)
  ice_cube_schedule.add_exception_time(now + 4.days)
  ice_cube_schedule.add_exception_time(now + 5.days)

  coruscate_schedule = Coruscate::Schedule.new(
    starts_at: Time.current,
    ends_at: Time.current + 365.days,
    time_zone: "Hawaii"
  )

  coruscate_schedule.repeat_weekly(:monday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
  coruscate_schedule.repeat_weekly(:tuesday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
  coruscate_schedule.repeat_weekly(:wednesday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
  coruscate_schedule.repeat_weekly(:thursday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
  coruscate_schedule.repeat_weekly(:friday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
  coruscate_schedule.add_exclusion(
    starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").beginning_of_day + 1.day).to_i,
    ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").end_of_day + 1.day).to_i
  )
  coruscate_schedule.add_exclusion(
    starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").beginning_of_day + 2.days).to_i,
    ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").end_of_day + 2.days).to_i
  )
  coruscate_schedule.add_exclusion(
    starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").beginning_of_day + 3.days).to_i,
    ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").end_of_day + 3.days).to_i
  )
  coruscate_schedule.add_exclusion(
    starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").beginning_of_day + 4.days).to_i,
    ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").end_of_day + 4.days).to_i
  )
  coruscate_schedule.add_exclusion(
    starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").beginning_of_day + 5.days).to_i,
    ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii").end_of_day + 5.days).to_i
  )

  def generate_ice_cube_occurrences(ice_cube_schedule)
    ice_cube_schedule.remaining_occurrences.size
  end

  def generate_coruscate_occurrences(coruscate_schedule)
    coruscate_schedule.occurrences.size
  end

  puts "Verifying generated occurrences are the same length:"
  puts generate_coruscate_occurrences(coruscate_schedule) == generate_ice_cube_occurrences(ice_cube_schedule)

  puts "Benchmarking Iterations Per Second (IPS)"
  Benchmark.ips do |x|
    x.report("IceCube:") { generate_ice_cube_occurrences(ice_cube_schedule) }
    x.report("Coruscate:") { generate_coruscate_occurrences(coruscate_schedule) }
  end

  puts "---"
  puts "Benchmarking Memory Use"
  Benchmark.memory do |x|
    x.report("IceCube:") { generate_ice_cube_occurrences(ice_cube_schedule) }
    x.report("Coruscate:") { generate_coruscate_occurrences(coruscate_schedule) }

    x.compare!
  end
end
