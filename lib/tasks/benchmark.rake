# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/time"
require "active_support/testing/time_helpers"
require "benchmark"
require "benchmark/ips"
require "benchmark/memory"
require "ice_cube"
require "montrose"

desc "Run benchmarks"
task :benchmark do
  require "reprise"

  schedule_start_time = Time.current
  schedule_end_time = Time.current + 1.year
  weekdays = %i[monday tuesday wednesday thursday friday saturday]
  exclusions = (1..5).map do |i|
    Time.current + i.days
  end

  ice_cube_schedule = IceCube::Schedule.new(schedule_start_time, end_time: schedule_end_time)
  weekdays.each { |w| ice_cube_schedule.add_recurrence_rule(IceCube::Rule.weekly(1).day(w).until(schedule_end_time)) }
  exclusions.each { |e| ice_cube_schedule.add_exception_time(e) }

  montrose_schedule = Montrose::Schedule.build do |s|
    # N.B. Not a truly apples-to-apples comparison, as Montrose doesn't support exclusion checks.
    weekdays.each do |w|
      s << Montrose.weekly(on: w, starts: schedule_start_time.to_date, until: schedule_end_time.to_date)
    end
  end

  reprise_schedule = Reprise::Schedule.new(starts_at: Time.current, ends_at: Time.current + 365.days, time_zone: "Hawaii")
  weekdays.each do |w|
    reprise_schedule.repeat_weekly(
      w,
      time_of_day: { hour: 1, minute: 2, second: 3 },
      duration_in_seconds: 300
    )
  end
  exclusions.each do |e|
    reprise_schedule.add_exclusion(starts_at: e.beginning_of_day, ends_at: e.end_of_day)
  end

  def generate_ice_cube_occurrences(ice_cube_schedule)
    ice_cube_schedule.remaining_occurrences.size
  end

  def generate_reprise_occurrences(reprise_schedule)
    reprise_schedule.occurrences.size
  end

  def generate_montrose_occurrences(montrose_schedule)
    montrose_schedule.events.to_a.size
  end

  puts "Verifying generated occurrences are the same length:"
  puts "---"
  puts "IceCube: #{generate_ice_cube_occurrences(ice_cube_schedule)}"
  # N.B. Montrose has no schedule exclusion feature, so we adjust for that.
  puts "Montrose: #{generate_montrose_occurrences(montrose_schedule) - exclusions.size}"
  puts "Reprise: #{generate_reprise_occurrences(reprise_schedule)}"

  puts "Benchmarking Iterations Per Second (IPS)"
  Benchmark.ips do |x|
    x.report("IceCube") { generate_ice_cube_occurrences(ice_cube_schedule) }
    x.report("Montrose") { generate_montrose_occurrences(montrose_schedule) }
    x.report("Reprise") { generate_reprise_occurrences(reprise_schedule) }
  end

  puts "---"
  puts "Benchmarking Memory Use"
  Benchmark.memory do |x|
    x.report("IceCube") { generate_ice_cube_occurrences(ice_cube_schedule) }
    x.report("Montrose") { generate_montrose_occurrences(montrose_schedule) }
    x.report("Reprise") { generate_reprise_occurrences(reprise_schedule) }

    x.compare!
  end
end
