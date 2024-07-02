# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/integer/time"
require "active_support/core_ext/time"
require_relative "coruscate/version"
require_relative "coruscate/coruscate"
require "forwardable"

module Coruscate
  class Error < StandardError; end

  class Schedule
    extend ::Forwardable

    # @param starts_at [Time]
    #   The beginning of the schedule; the earliest possible moment for a valid occurrence.
    # @param ends_at [Time]
    #   The end of the schedule; the latest possible moment for a valid occurrence.
    # @param time_zone [String]
    #   Must be an unambiguous, valid time-zone according to `ActiveSupport::TimeZone::find_tzinfo`.
    #   See https://github.com/tzinfo/tzinfo/issues/53
    # @raise [TZInfo::InvalidTimezoneIdentifier] if the time zone is ambiguous or invalid.
    def initialize(starts_at:, ends_at:, time_zone:)
      @starts_at = starts_at
      @ends_at = ends_at
      @time_zone = ActiveSupport::TimeZone::find_tzinfo(time_zone).identifier
    end

    # @return [Array<Coruscate::Core::Occurrence>]
    def occurrences
      internal_schedule.occurrences
    end

    def_delegators :internal_schedule,
                   :add_exclusion,
                   :add_exclusions,
                   :repeat_weekly

    private

    attr_reader :starts_at, :ends_at, :time_zone

    def internal_schedule
      return @_internal_schedule if defined?(@_internal_schedule)

      @_internal_schedule = ::Coruscate::Core::Schedule.new(
        starts_at.to_i,
        ends_at.to_i,
        time_zone
      )
    end
  end
end
