# frozen_string_literal: true

require "spec_helper"

RSpec.describe "#repeat_daily", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Reprise::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 5.days }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  it_behaves_like "a series that supports optional occurrence labels" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_daily(**series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports the duration_in_seconds argument" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_daily(**series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports an optional count argument" do
    let(:series_options_hash) { series_options }
    let(:occurrences) do
      schedule.repeat_daily(**series_options_hash)
      schedule.occurrences
    end
  end

  it "generates an array of daily occurrences" do
    schedule.repeat_daily(**series_options(time_of_day: { hour: 1, minute: 2, second: 3 }))

    expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
      .to contain_exactly(
        "Mon Mar 11 2024 01:02AM -0700",
        "Tue Mar 12 2024 01:02AM -0700",
        "Wed Mar 13 2024 01:02AM -0700",
        "Thu Mar 14 2024 01:02AM -0700",
        "Fri Mar 15 2024 01:02AM -0700"
      )
  end

  context "when the schedule starts on a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) { (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024).in_time_zone(time_zone) }

    it "generates an array of occurrences starting from the DST change" do
      schedule.repeat_daily(time_of_day: nil, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
        # N.B. The first occurrence begins
        # after the local time gap, one
        # hour forward.
        "Sun Mar 10 2024 01:59AM -0800",
        "Mon Mar 11 2024 01:59AM -0700",
        "Tue Mar 12 2024 01:59AM -0700",
        "Wed Mar 13 2024 01:59AM -0700",
        "Thu Mar 14 2024 01:59AM -0700"
      )
    end
  end

  context "when the schedule crosses a transition from Standard Time to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 1.day).in_time_zone(time_zone)
    end

    it "generates an array of daily occurrences across the DST change" do
      schedule.repeat_daily(**series_options)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Sat Mar  9 2024 10:15PM -0800",
          "Sun Mar 10 2024 10:15PM -0700",
          "Mon Mar 11 2024 10:15PM -0700",
          "Tue Mar 12 2024 10:15PM -0700",
          "Wed Mar 13 2024 10:15PM -0700"
        )
    end

    context "and the series time of day falls during an ambiguous time" do
      it "generates an array of daily occurrences across the DST change" do
        schedule.repeat_daily(**series_options(time_of_day: { hour: 2, minute: 15 }))

        expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
          .to contain_exactly(
            "Sat Mar  9 2024 02:15AM -0800",
            # N.B. there is no 2:15 AM on this date;
            # the time zone advances by 1 hour at 2:00am.
            # We follow the Google Calendar approach, and return
            # the exact same UTC time, but in the new offset.
            "Sun Mar 10 2024 03:15AM -0700",
            "Mon Mar 11 2024 02:15AM -0700",
            "Tue Mar 12 2024 02:15AM -0700",
            "Wed Mar 13 2024 02:15AM -0700"
          )
      end
    end
  end

  context "when the schedule crosses a transition from Daylight Savings Time (DST) to Standard Time (ST)" do
    let(:starts_at) { TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_ST_2024 - 1.day }

    it "generates an array of daily occurrences across the ST change" do
      schedule.repeat_daily(**series_options(time_of_day: { hour: 1, minute: 15 }))

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Sat Nov  2 2024 01:15AM -0700",
          # N.B. Clocks are turned back 1 hour at 2:00am
          # on November 3rd; we bias towards the new offset,
          # and return the "second" instance of the time.
          "Sun Nov  3 2024 01:15AM -0800",
          "Mon Nov  4 2024 01:15AM -0800",
          "Tue Nov  5 2024 01:15AM -0800",
          "Wed Nov  6 2024 01:15AM -0800"
        )
    end
  end
end
