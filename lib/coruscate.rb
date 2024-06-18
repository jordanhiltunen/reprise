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
      @time_zone = time_zone
      # TODO: validate the time zone, reject ambiguous zones.
    end

    def occurrences
      return @_occurrences if defined?(@_occurrences)

      @_occurrences = internal_schedule.occurrences.map do |unix_timestamp|
        Time.at(unix_timestamp).in_time_zone(time_zone)
      end
    end

    def_delegators :internal_schedule, :set_exclusions, :add_exclusion

    private

    attr_reader :start_time, :end_time, :time_zone

    def inferred_tzinfo_time_zone
      return @_inferred_tzinfo_time_zone if defined?(@_inferred_tzinfo_time_zone)

      @_inferred_tzinfo_time_zone = ActiveSupport::TimeZone::find_tzinfo(time_zone).identifier
    end

    def internal_schedule
      return @_internal_schedule if defined?(@_internal_schedule)

      @_internal_schedule = ::Coruscate::Core::Schedule.new(
        start_time.to_i,
        end_time.to_i,
        inferred_tzinfo_time_zone
      )
    end
  end
end
