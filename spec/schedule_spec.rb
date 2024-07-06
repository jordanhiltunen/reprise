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
        starts_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") - 30.minutes).to_i,
        ends_at_unix_timestamp: (Time.current.in_time_zone("Hawaii") + 5.minutes).to_i
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

  describe "#repeat_monthly_by_nth_weekday" do
    let(:ends_at) { Time.current + 11.months }

    it "generates an array of monthly occurrences with a fixed weekday" do
      schedule.repeat_monthly_by_nth_weekday("tuesday", 2, { hour: 1, minute: 2, second: 3 }, 300)

      expect(schedule.occurrences.size).to eq(11)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
             "Tue Jul 16 2024 01:02AM -1000",
             "Tue Aug 20 2024 01:02AM -1000",
             "Tue Sep 17 2024 01:02AM -1000",
             "Tue Oct 15 2024 01:02AM -1000",
             "Tue Nov 19 2024 01:02AM -1000",
             "Tue Dec 17 2024 01:02AM -1000",
             "Tue Jan 21 2025 01:02AM -1000",
             "Tue Feb 18 2025 01:02AM -1000",
             "Tue Mar 18 2025 01:02AM -1000",
             "Tue Apr 15 2025 01:02AM -1000",
             "Tue May 20 2025 01:02AM -1000"
           )
    end

    it "allows negative indexing into the monthly occurrences" do
      schedule.repeat_monthly_by_nth_weekday("friday", -1, { hour: 1, minute: 2, second: 3 }, 300)

      expect(schedule.occurrences.size).to eq(10)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
             "Fri Jul 26 2024 01:02AM -1000",
             "Fri Aug 30 2024 01:02AM -1000",
             "Fri Sep 27 2024 01:02AM -1000",
             "Fri Oct 25 2024 01:02AM -1000",
             "Fri Nov 29 2024 01:02AM -1000",
             "Fri Dec 27 2024 01:02AM -1000",
             "Fri Jan 31 2025 01:02AM -1000",
             "Fri Feb 28 2025 01:02AM -1000",
             "Fri Mar 28 2025 01:02AM -1000",
             "Fri Apr 25 2025 01:02AM -1000",
           )
    end

    it "can handle nth weekday edge cases that do not occur every month" do
      # The fifth (NB: 4; zeroth indexing) wednesday of a month is relatively rare.
      schedule.repeat_monthly_by_nth_weekday("wednesday", 4, { hour: 1, minute: 2, second: 3 }, 300)

      expect(schedule.occurrences.size).to eq(4)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
             "Wed Apr 30 2025 01:02AM -1000",
             "Wed Jan 29 2025 01:02AM -1000",
             "Wed Jul 31 2024 01:02AM -1000",
             "Wed Oct 30 2024 01:02AM -1000"
           )
    end
  end

  describe "#repeat_monthly_by_day" do
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

    it "handles indexing into non-universal day numbers" do
      schedule.repeat_monthly_by_day(31, { hour: 1, minute: 2, second: 3 }, 300)

      expect(schedule.occurrences.size).to eq(4)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
             "Wed Jul 31 2024 01:02AM -1000",
             "Sat Aug 31 2024 01:02AM -1000",
             "Mon Sep 30 2024 01:02AM -1000", # UGH
             "Wed Oct 30 2024 01:02AM -1000"
      )
    end
  end

  describe "#repeat_weekly" do
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

  describe "#repeat_hourly" do
    let(:ends_at) { Time.current + 6.hours }

    it "generates an array of monthly occurrences" do
      schedule.repeat_hourly(
        initial_time_of_day: { hour: 1, minute: 2, second: 3 },
        duration_in_seconds: 300
      )

      expect(schedule.occurrences.size).to eq(5)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
              "Sun Jun 30 2024 01:02AM -1000",
              "Sun Jun 30 2024 02:02AM -1000",
              "Sun Jun 30 2024 03:02AM -1000",
              "Sun Jun 30 2024 04:02AM -1000",
              "Sun Jun 30 2024 05:02AM -1000"
           )
    end

    it "generates an array of hourly occurrences across a DST change" do
    end
  end
end
