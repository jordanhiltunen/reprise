# frozen_string_literal: true

require "spec_helper"

RSpec.describe Reprise::Schedule, aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Reprise::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:time_zone) { "Hawaii" }
  let(:starts_at) { Time.new(2024, 6, 30, 0, 0, 0, "-10:00") }
  let(:ends_at) { (starts_at + 4.weeks) }
  let(:event_duration_in_seconds) { 5.hours }

  describe "#initialize" do
    context "when the time zone is invalid" do
      let(:time_zone) { "nonsense" }

      it "raises a TZInfo::InvalidTimezoneIdentifier" do
        expect { schedule }.to raise_error(TZInfo::InvalidTimezoneIdentifier, "Invalid identifier: nonsense")
      end
    end

    context "when the time zone is ambiguous" do
      # https://github.com/tzinfo/tzinfo/issues/53#issuecomment-235852722
      let(:time_zone) { "CEST" }

      it "raises a TZInfo::InvalidTimezoneIdentifier" do
        expect { schedule }.to raise_error(TZInfo::InvalidTimezoneIdentifier, "Invalid identifier: CEST")
      end
    end
  end

  it "will use the start time of the schedule if a time_of_day for the series is not given" do
    schedule.repeat_weekly(:tuesday, duration_in_seconds: 300)

    expect(schedule.occurrences.size).to eq(4)
    expect(
      schedule.occurrences.map { |o| o.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }
    ).to contain_exactly(
       "Tue Jul  2 2024 12:00AM -1000",
       "Tue Jul  9 2024 12:00AM -1000",
       "Tue Jul 16 2024 12:00AM -1000",
       "Tue Jul 23 2024 12:00AM -1000"
     )
  end

  it "supports the accumulation of occurrences from multiple recurring series" do
    schedule.repeat_weekly(:tuesday, time_of_day: { hour: 1, minute: 2, second: 3 }, duration_in_seconds: 300)
    schedule.repeat_weekly(:wednesday, time_of_day: { hour: 2, minute: 3, second: 4 }, duration_in_seconds: 300)

    expect(schedule.occurrences.size).to eq(8)
    expect(
      schedule.occurrences.map { |o| o.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }
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

  it "supports the accumulation of occurrences from multiple recurring series with their own independent bookends" do
    schedule.repeat_weekly(:tuesday,
                           time_of_day: { hour: 9, minute: 0 }, duration_in_seconds: 300,
                           starts_at: starts_at + 2.weeks, ends_at:)
    schedule.repeat_weekly(:wednesday,
                           time_of_day: { hour: 4, minute: 7, second: 4 }, duration_in_seconds: 300,
                           ends_at: starts_at + 6.weeks)

    expect(schedule.occurrences.size).to eq(8)
    expect(
      schedule.occurrences.map { |o| o.start_time.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }
    ).to contain_exactly(
      "Wed Jul  3 2024 04:07AM -1000",
      "Wed Jul 10 2024 04:07AM -1000",
      "Tue Jul 16 2024 09:00AM -1000", # Tuesday series comes in 2 weeks later.
      "Wed Jul 17 2024 04:07AM -1000",
      "Tue Jul 23 2024 09:00AM -1000",
      "Wed Jul 24 2024 04:07AM -1000",
      "Wed Jul 31 2024 04:07AM -1000",
      "Wed Aug  7 2024 04:07AM -1000"
     )
  end

  describe "#occurrences" do
    let(:occurrences) do
      schedule.repeat_weekly(
        :sunday,
        time_of_day: { hour: 0, minute: 1, second: 2 },
        duration_in_seconds: event_duration_in_seconds,
        label: "My Weekly Occurrence"
      )
      schedule.occurrences
    end

    it "returns an array of Reprise::Core::Occurrence" do
      expect(occurrences.all? { |occurrence| occurrence.is_a?(Reprise::Core::Occurrence) }).to eq(true)
    end

    it "exposes #start_time and #end_time methods on the occurrences" do
      first_occurrence = occurrences.first

      expect(first_occurrence.start_time).to be_a(Time)
      expect(first_occurrence.start_time.in_time_zone(time_zone).to_s).to eq("2024-06-30 00:01:02 -1000")
      expect(first_occurrence.end_time).to be_a(Time)
      expect(first_occurrence.end_time.in_time_zone(time_zone).to_s).to eq("2024-06-30 05:01:02 -1000")
    end

    it "exposes an optional label on each occurrence" do
      first_occurrence = occurrences.first

      expect(first_occurrence.label).to eq("My Weekly Occurrence")
    end

    it "exposes an #inspect method on the occurrences" do
      first_occurrence = occurrences.first

      expect(first_occurrence.inspect).to eq(
        '<Reprise::Core::Occurrence start_time="2024-06-30 06:01:02 -0400" end_time="2024-06-30 11:01:02 -0400" label="My Weekly Occurrence">'
      )
    end
  end
end
