# frozen_string_literal: true

require "spec_helper"

RSpec.describe "exclusions", aggregate_failures: true do
  include SeriesHelpers

  subject(:schedule) { Coruscate::Schedule.new(starts_at:, ends_at:, time_zone:) }

  let(:starts_at) { Time.new(2024, 6, 30, 0, 0, 0, "-10:00") }
  let(:ends_at) { starts_at + 4.weeks }
  let(:time_zone) { "Hawaii" }
  let(:event_duration_in_seconds) { 5.minutes }

  describe "#add_exclusion" do
    it "allows users to specify exclusions that result in removed occurrences" do
      schedule.repeat_weekly(:sunday, time_of_day: { hour: 0, minute: 1, second: 2 },
        duration_in_seconds: event_duration_in_seconds)

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Jun 30 2024 12:01AM -1000",
          "Sun Jul  7 2024 12:01AM -1000",
          "Sun Jul 14 2024 12:01AM -1000",
          "Sun Jul 21 2024 12:01AM -1000"
        )

      schedule.add_exclusion(
        starts_at: starts_at - 30.minutes,
        ends_at: starts_at + 5.minutes
      )

      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Jul  7 2024 12:01AM -1000",
          "Sun Jul 14 2024 12:01AM -1000",
          "Sun Jul 21 2024 12:01AM -1000"
        )
    end
  end

  describe "#add_exclusions" do
    it "allows users to specify multiple exclusions" do
      schedule.repeat_weekly(:sunday, time_of_day: { hour: 0, minute: 1, second: 2 }, duration_in_seconds: 300)

      expect(schedule.occurrences.size).to eq(4)
      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Jun 30 2024 12:01AM -1000",
          "Sun Jul  7 2024 12:01AM -1000",
          "Sun Jul 14 2024 12:01AM -1000",
          "Sun Jul 21 2024 12:01AM -1000"
        )

      schedule.add_exclusions(
        [
          [
            (starts_at - 30.minutes).to_i,
            (starts_at + 5.minutes).to_i
          ],
          [
            (starts_at + 7.days).to_i,
            (starts_at + 8.days).to_i
          ]
        ]
      )

      expect(schedule.occurrences.size).to eq(2)
      expect(schedule.occurrences.map { |o| localized_occurrence_start_time(o) })
        .to contain_exactly(
          "Sun Jul 14 2024 12:01AM -1000",
          "Sun Jul 21 2024 12:01AM -1000"
        )
    end
  end
end
