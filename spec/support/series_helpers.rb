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
end
