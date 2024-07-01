# frozen_string_literal: true

require "spec_helper"

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
end
