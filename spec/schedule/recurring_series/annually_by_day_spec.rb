# frozen_string_literal: true

require "spec_helper"

RSpec.describe "#repeat_annually_by_day", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Reprise::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024.in_time_zone(time_zone) }
  let(:ends_at) { starts_at + 6.years }
  let(:time_zone) { TimeZoneHelpers::LOS_ANGELES_TIME_ZONE }

  it_behaves_like "a series that supports optional occurrence labels" do
    let(:series_options_hash) { series_options }
    let(:occurrences) do
      schedule.repeat_annually_by_day(200, **series_options_hash)
      schedule.occurrences
    end
  end

  it_behaves_like "a series that supports the duration_in_seconds argument" do
    let(:series_options_hash) { series_options }
    let(:occurrences) do
      schedule.repeat_annually_by_day(200, **series_options_hash)
      schedule.occurrences
    end
  end

  it "generates an array of annual occurrences" do
    schedule.repeat_annually_by_day(200, **series_options)

    expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
      .to contain_exactly(
        "Thu Jul 18 2024 10:15PM -0700",
        "Sat Jul 19 2025 10:15PM -0700",
        "Sun Jul 19 2026 10:15PM -0700",
        "Mon Jul 19 2027 10:15PM -0700",
        "Tue Jul 18 2028 10:15PM -0700",
        "Thu Jul 19 2029 10:15PM -0700"
      )
  end

  it "skips years when the requested day does not appear" do
    schedule.repeat_annually_by_day(366, **series_options)

    expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
      .to contain_exactly(
        "Sun Dec 31 2028 10:15PM -0800",
        "Tue Dec 31 2024 10:15PM -0800"
      )
  end

  context "when the schedule starts on a transition from Standard Time (ST) to Daylight Savings Time (DST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_DST_2024 + 5.minutes).in_time_zone(time_zone)
    end

    it "generates an array of occurrences starting from the DST change" do
      schedule.repeat_annually_by_day(70, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          # N.B. The first occurrence begins
          # after the local time gap, one
          # hour forward.
          "Sun Mar 10 2024 03:15AM -0700",
          "Tue Mar 11 2025 02:15AM -0700",
          "Wed Mar 11 2026 02:15AM -0700",
          "Thu Mar 11 2027 02:15AM -0800",
          "Fri Mar 10 2028 02:15AM -0800",
          "Sun Mar 11 2029 03:15AM -0700"
        )
    end
  end

  context "when the schedule crosses a transition from Daylight Savings Time (DST) to Standard Time (ST)" do
    let(:starts_at) do
      (TimeZoneHelpers::ONE_MINUTE_BEFORE_LA_TRANSITION_TO_ST_2024 - 1.month)
    end

    it "generates an array of occurrences across the ST change" do
      schedule.repeat_annually_by_day(308, time_of_day: { hour: 2, minute: 15 }, duration_in_seconds: 30.minutes)

      expect(schedule.occurrences.map { |o| localized_occurrence_starts_at(o) })
        .to contain_exactly(
          # N.B. Transition to ST, with a bias
          # towards the instance of the time that
          # falls in the new offset.
          "Sun Nov  3 2024 02:15AM -0800",
          "Tue Nov  4 2025 02:15AM -0800",
          "Wed Nov  4 2026 02:15AM -0800",
          "Thu Nov  4 2027 02:15AM -0700",
          "Fri Nov  3 2028 02:15AM -0700",
          "Sun Nov  4 2029 02:15AM -0800"
        )
    end
  end
end
