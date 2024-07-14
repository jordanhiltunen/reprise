# frozen_string_literal: true

require "spec_helper"

RSpec.describe "#repeat_minutely", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Coruscate::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 5.minutes }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  it_behaves_like "a series that supports optional occurrence labels" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_minutely(**series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports the duration_in_seconds argument" do
    let(:series_options_hash) { series_options(time_of_day: { hour: 1, minute: 2, second: 3 }) }
    let(:occurrences) do
      schedule.repeat_minutely(**series_options_hash)
      schedule.occurrences
    end
  end

  it "generates an array of minutely occurrences" do
    schedule.repeat_minutely(**series_options, time_of_day: nil)

    expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
      .to contain_exactly(
        "Sun Mar 10 2024 03:00AM -0700",
        "Sun Mar 10 2024 03:01AM -0700",
        "Sun Mar 10 2024 03:02AM -0700",
        "Sun Mar 10 2024 03:03AM -0700"
      )
  end

  context "when an interval is included" do
    let(:ends_at) { starts_at + 10.minutes }

    it "generates an array of every nth occurrence" do
      schedule.repeat_minutely(**series_options, time_of_day: nil, interval: 2)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Mar 10 2024 03:00AM -0700",
          "Sun Mar 10 2024 03:02AM -0700",
          "Sun Mar 10 2024 03:04AM -0700",
          "Sun Mar 10 2024 03:06AM -0700",
          "Sun Mar 10 2024 03:08AM -0700"
        )
    end
  end

  context "when the schedule starts on a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 + 2.minutes).in_time_zone(time_zone)
    end

    it "generates an array of occurrences starting from the DST change" do
      schedule.repeat_minutely(time_of_day: { hour: 2, minute: 1 }, duration_in_seconds: 30.seconds)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          # N.B. The first occurrence begins
          # after the local time gap, one
          # hour forward from the desired (but non-existent)
          # local time.
          "Sun Mar 10 2024 03:02AM -0700",
          "Sun Mar 10 2024 03:03AM -0700",
          "Sun Mar 10 2024 03:04AM -0700",
          "Sun Mar 10 2024 03:05AM -0700"
        )
    end
  end

  context "when the schedule crosses a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 - 1.minute).in_time_zone(time_zone)
    end

    it "generates an array of minutely occurrences across the DST change" do
      schedule.repeat_minutely(**series_options, time_of_day: nil)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Mar 10 2024 01:59AM -0800",
          # N.B. Notice the DST jump
          "Sun Mar 10 2024 03:00AM -0700",
          "Sun Mar 10 2024 03:01AM -0700",
          "Sun Mar 10 2024 03:02AM -0700"
        )
    end
  end

  context "when the schedule crosses a transition from Daylight Savings Time (DST) to Standard Time (ST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_ST_2024 - 2.minutes).in_time_zone(time_zone)
    end
    let(:ends_at) { starts_at + (1.hours + 5.minutes) }

    it "generates an array of daily occurrences across the ST change" do
      schedule.repeat_minutely(**series_options, time_of_day: nil)

      occurrences = schedule.occurrences
      first_three_occurrences = occurrences.first(3)
      last_five_occurrences = occurrences.last(5)

      expect(first_three_occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Nov  3 2024 12:58AM -0700",
          "Sun Nov  3 2024 12:59AM -0700",
          "Sun Nov  3 2024 01:00AM -0700",
        )

      expect(last_five_occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Nov  3 2024 01:57AM -0700",
          "Sun Nov  3 2024 01:58AM -0700",
          "Sun Nov  3 2024 01:59AM -0700",
          # N.B. Clocks are turned back 1 hour at 2:00am
          "Sun Nov  3 2024 01:00AM -0800",
          "Sun Nov  3 2024 01:01AM -0800"
        )
    end
  end
end
