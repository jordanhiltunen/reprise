# frozen_string_literal: true

require "spec_helper"
require "benchmark"
require "ice_cube"
require "benchmark/ips"
require "benchmark/memory"

RSpec.describe Coruscate::Schedule do
  subject(:schedule) do
    Coruscate::Schedule.new(starts_at: starts_at, ends_at: ends_at, time_zone: time_zone)
  end

  let(:starts_at) { Time.current }
  let(:ends_at) { Time.current + 4.weeks }
  let(:time_zone) { "Hawaii" }

  before { travel_to Time.new(2024, 6, 30, 0, 0, 0, "-10:00") } # Hawaii

  def localized_occurrence_start_time(occurrence)
    occurrence.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z")
  end

  describe "#initialize" do
    context "when the time zone is invalid" do
      let(:time_zone) { "nonsense" }

      it "raises a `TZInfo::InvalidTimezoneIdentifier` error" do
        expect { schedule }.to raise_error(TZInfo::InvalidTimezoneIdentifier, "Invalid identifier: nonsense")
      end
    end

    context "when the time zone is ambiguous" do
      # https://github.com/tzinfo/tzinfo/issues/53#issuecomment-235852722
      let(:time_zone) { "CEST" }

      it "raises a `TZInfo::InvalidTimezoneIdentifier` error" do
        expect { schedule }.to raise_error(TZInfo::InvalidTimezoneIdentifier, "Invalid identifier: CEST")
      end
    end
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

    it "supports the accumulation of occurrences from multiple recurring series" do
      schedule.repeat_weekly("tuesday", { hour: 1, minute: 2, second: 3 }, 300)
      schedule.repeat_weekly("wednesday", { hour: 2, minute: 3, second: 4 }, 300)

      expect(schedule.occurrences.size).to eq(8)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
             "Tue Jul  2 2024 01:02AM -1000",
             "Wed Jul  3 2024 02:03AM -1000",
             "Tue Jul  9 2024 01:02AM -1000",
             "Wed Jul 10 2024 02:03AM -1000",
             "Tue Jul 16 2024 01:02AM -1000",
             "Wed Jul 17 2024 02:03AM -1000",
             "Tue Jul 23 2024 01:02AM -1000",
             "Wed Jul 24 2024 02:03AM -1000"
           )
    end

    context "when the schedule crosses a daylight savings change" do
      let!(:starts_at) { Time.new(2024, 3, 2, 0, 0, 0) }
      let!(:ends_at) { starts_at + 4.weeks }
      let!(:time_zone) { "America/Los_Angeles" }

      it "holds the local occurrence time constant across the DST change" do
        schedule.repeat_weekly("sunday", { hour: 0, minute: 1, second: 2 }, 300)

        pp "OCCURRENCES"
        pp schedule.occurrences.map { |o| o.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }

        expect(
          schedule.occurrences.map { |o| o.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }
        ).to contain_exactly(
               "Sun Mar  3 2024 12:01AM -0800",
               "Sun Mar 10 2024 12:01AM -0800",
               "Sun Mar 17 2024 12:01AM -0700",
               "Sun Mar 24 2024 12:01AM -0700"
             )
      end
    end
  end

  describe "#repeats_monthly_by_day" do
    let(:ends_at) { Time.current + 5.months }

    it "generates an array of monthly occurrences" do
      schedule.repeat_monthly_by_day(12, { hour: 1, minute: 2, second: 3 }, 300)

      expect(schedule.occurrences.size).to eq(5)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
              "Fri Jul 12 2024 01:02AM -1000",
              "Mon Aug 12 2024 01:02AM -1000",
              "Sat Oct 12 2024 01:02AM -1000",
              "Thu Sep 12 2024 01:02AM -1000",
              "Tue Nov 12 2024 01:02AM -1000"
           )
    end
  end
end
