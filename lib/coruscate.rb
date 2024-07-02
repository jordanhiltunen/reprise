require "active_support"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/time"
require "coruscate/version"
require_relative "coruscate/coruscate"
require "forwardable"

module Coruscate
  class Error < StandardError; end

  class Schedule
    extend ::Forwardable

    def initialize(start_time:, end_time:, time_zone:)
      @start_time = start_time
      @end_time = end_time
    def initialize(starts_at:, ends_at:, time_zone:)
      @starts_at = starts_at
      @ends_at = ends_at
      @time_zone = time_zone
      # TODO: validate the time zone, reject ambiguous zones.
    end

    def occurrences
      internal_schedule.occurrences
    end

    def_delegators :internal_schedule,
                   :add_exclusion,
                   :add_exclusions,
                   :repeat_weekly

    private

    attr_reader :starts_at, :ends_at, :time_zone

    def inferred_tzinfo_time_zone
      return @_inferred_tzinfo_time_zone if defined?(@_inferred_tzinfo_time_zone)

      @_inferred_tzinfo_time_zone = ActiveSupport::TimeZone::find_tzinfo(time_zone).identifier
    end

    def internal_schedule
      return @_internal_schedule if defined?(@_internal_schedule)

      @_internal_schedule = ::Coruscate::Core::Schedule.new(
        starts_at.to_i,
        ends_at.to_i,
        inferred_tzinfo_time_zone
      )
    end
  end
end
