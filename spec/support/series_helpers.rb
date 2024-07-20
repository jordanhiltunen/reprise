# frozen_string_literal: true

module SeriesHelpers
  DEFAULT_SERIES_OPTIONS = {
    duration_in_seconds: 1.hour.seconds,
    time_of_day: { hour: 22, minute: 15 },
    interval: 1,
    starts_at: nil,
    ends_at: nil
  }.freeze

  def series_options(series_options = {})
    DEFAULT_SERIES_OPTIONS.merge(series_options)
  end

  def localized_occurrence_start_and_end_time(occurrence)
    [occurrence.starts_at, occurrence.ends_at]
      .map { |o| o.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z") }
      .join(" - ")
  end

  def localized_occurrence_starts_at(occurrence)
    occurrence.starts_at.in_time_zone(time_zone).strftime("%a %b %e %Y %I:%M%p %z")
  end
end
