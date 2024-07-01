# frozen_string_literal: true

require "spec_helper"
require "benchmark"
require "ice_cube"
require "benchmark/ips"
require "benchmark/memory"

RSpec.describe Coruscate::Schedule do
  subject(:schedule) do
    Coruscate::Schedule.new(
      start_time: Time.current,
      end_time: Time.current + 4.weeks,
      time_zone: time_zone
    )
  end

  let(:time_zone) { "Hawaii" }

  before { travel_to Time.new(2024, 6, 30, 0, 0, 0, "-10:00") } # Hawaii

  def localized_occurrence_start_time(occurrence)
    occurrence.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z")
  end

  describe "#add_exclusion" do
    it "allows users to specify exclusions that result in removed occurrences" do
      schedule.repeat_weekly("sunday", { hour: 0, minute: 1, second: 2 }, 300)

      expect(schedule.occurrences.size).to eq(4)
      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
        to contain_exactly(
             "Sun Jun 30 2024 12:01AM -1000",
             "Sun Jul  7 2024 12:01AM -1000",
             "Sun Jul 14 2024 12:01AM -1000",
             "Sun Jul 21 2024 12:01AM -1000"
           )

      schedule.add_exclusion(
        (Time.current.in_time_zone("Hawaii") - 30.minutes).to_i,
        (Time.current.in_time_zone("Hawaii") + 5.minutes).to_i
      )

      expect(schedule.occurrences.size).to eq(3)
      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
        to contain_exactly(
             "Sun Jul  7 2024 12:01AM -1000",
             "Sun Jul 14 2024 12:01AM -1000",
             "Sun Jul 21 2024 12:01AM -1000"
           )
    end
  end

  describe "#add_exclusions" do
    it "allows users to specify multiple exclusions" do
      schedule.repeat_weekly("sunday", { hour: 0, minute: 1, second: 2 }, 300)

      expect(schedule.occurrences.size).to eq(4)
      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
        to contain_exactly(
             "Sun Jun 30 2024 12:01AM -1000",
             "Sun Jul  7 2024 12:01AM -1000",
             "Sun Jul 14 2024 12:01AM -1000",
             "Sun Jul 21 2024 12:01AM -1000"
           )

      schedule.add_exclusions(
        [
          [
            (Time.current.in_time_zone("Hawaii") - 30.minutes).to_i,
            (Time.current.in_time_zone("Hawaii") + 5.minutes).to_i
          ],
          [
            (Time.current.in_time_zone("Hawaii") + 7.days).to_i,
            (Time.current.in_time_zone("Hawaii") + 8.days).to_i
          ]
        ]
      )

      expect(schedule.occurrences.size).to eq(2)
      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) }).
        to contain_exactly(
             "Sun Jul 14 2024 12:01AM -1000",
             "Sun Jul 21 2024 12:01AM -1000"
           )
    end
  end

  describe "#repeats_weekly" do
    it "generates an array of weekly occurrences" do
      schedule.repeat_weekly("tuesday", { hour: 1, minute: 2, second: 3 }, 300)

      expect(schedule.occurrences.size).to eq(4)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
             "Tue Jul  2 2024 01:02AM -1000",
             "Tue Jul  9 2024 01:02AM -1000",
             "Tue Jul 16 2024 01:02AM -1000",
             "Tue Jul 23 2024 01:02AM -1000"
           )
    end
  end

  describe "Benchmarks" do
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
        start_time: Time.current,
        end_time: Time.current + 365.days,
        time_zone: time_zone
      )

      schedule.repeat_weekly("tuesday", { hour: 1, minute: 2, second: 3 }, 300)
      schedule.repeat_weekly("wednesday", { hour: 1, minute: 2, second: 3 }, 300)
      schedule.add_exclusion(
        (Time.current.in_time_zone("Hawaii") - 30.minutes).to_i,
        (Time.current.in_time_zone("Hawaii") + 5.minutes).to_i
      )

      schedule.occurrences.size
    end

    it "is faster than ice cube" do
      Benchmark.ips do |x|
        x.report("IceCube:") { generate_ice_cube_occurrences }
        x.report("Coruscate:") { generate_coruscate_occurrences }
      end
    end

    it "is more memory-efficient than ice cube" do
      Benchmark.memory do |x|
        x.report("IceCube:") { generate_ice_cube_occurrences }
        x.report("Coruscate:") { generate_coruscate_occurrences }

        x.compare!
      end
    end
  end
end
