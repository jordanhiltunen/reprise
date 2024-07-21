# frozen_string_literal: true

require "spec_helper"

RSpec.describe "#repeat_hourly", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Reprise::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 6.hours }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  it_behaves_like "a series that supports optional occurrence labels" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_hourly(**series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports the duration_in_seconds argument" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_hourly(**series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports an optional count argument" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_hourly(**series_options_hash)
      schedule.occurrences
    end
  end

  it "generates an array of hourly occurrences" do
    schedule.repeat_hourly(**series_options(time_of_day: { hour: 1, minute: 2, second: 3 }))

    expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
      .to contain_exactly(
        "Sun Mar 10 2024 03:02AM -0700",
        "Sun Mar 10 2024 04:02AM -0700",
        "Sun Mar 10 2024 05:02AM -0700",
        "Sun Mar 10 2024 06:02AM -0700",
        "Sun Mar 10 2024 07:02AM -0700",
        "Sun Mar 10 2024 08:02AM -0700"
      )
  end

  context "when an interval is included" do
    let(:ends_at) { starts_at + 12.hours }

    it "generates an array of every nth occurrence" do
      schedule.repeat_hourly(
        time_of_day: { hour: 1, minute: 2, second: 3 },
        duration_in_seconds: 300,
        interval: 2
      )

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Sun Mar 10 2024 01:02PM -0700",
          "Sun Mar 10 2024 03:02AM -0700",
          "Sun Mar 10 2024 05:02AM -0700",
          "Sun Mar 10 2024 07:02AM -0700",
          "Sun Mar 10 2024 09:02AM -0700",
          "Sun Mar 10 2024 11:02AM -0700"
        )
    end
  end

  context "when the schedule starts on a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 + 5.minutes).in_time_zone(time_zone)
    end

    it "generates an array of occurrences starting from the DST change" do
      schedule.repeat_hourly(time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          # N.B. The first occurrence begins
          # after the local time gap, one
          # hour forward.
          "Sun Mar 10 2024 03:15AM -0700",
          "Sun Mar 10 2024 04:15AM -0700",
          "Sun Mar 10 2024 05:15AM -0700",
          "Sun Mar 10 2024 06:15AM -0700",
          "Sun Mar 10 2024 07:15AM -0700",
          "Sun Mar 10 2024 08:15AM -0700"
        )
    end
  end

  context "when the schedule crosses a transition from Standard Time to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 1.hour).in_time_zone(time_zone)
    end

    it "generates an array of daily occurrences across the DST change" do
      schedule.repeat_hourly(**series_options, time_of_day: nil)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Sun Mar 10 2024 12:59AM -0800",
          "Sun Mar 10 2024 01:59AM -0800",
          # N.B. Notice the DST jump to 3:59 AM.
          # https://www.timeanddate.com/news/time/usa-start-dst-2024.html
          "Sun Mar 10 2024 03:59AM -0700",
          "Sun Mar 10 2024 04:59AM -0700",
          "Sun Mar 10 2024 05:59AM -0700",
          "Sun Mar 10 2024 06:59AM -0700"
        )
    end
  end

  context "when the schedule crosses a transition from Daylight Savings Time (DST) to Standard Time (ST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_ST_2024 - 1.hour)
    end

    it "generates an array of occurrences across the ST change" do
      schedule.repeat_hourly(time_of_day: nil, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          "Sat Nov  2 2024 11:59PM -0700",
          "Sun Nov  3 2024 01:59AM -0700",
          # N.B. Transition to ST, with a bias
          # towards the instance of the time that
          # falls in the new offset.
          "Sun Nov  3 2024 01:59AM -0800",
          "Sun Nov  3 2024 02:59AM -0800",
          "Sun Nov  3 2024 03:59AM -0800",
          "Sun Nov  3 2024 12:59AM -0700"
        )
    end
  end
end
