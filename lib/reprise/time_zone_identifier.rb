# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"

module Reprise
  class InvalidTimeZoneError < Reprise::Error; end

  # @api private
  class TimeZoneIdentifier
    # https://github.com/rails/rails/blob/19eebf6d33dd15a0172e3ed2481bec57a89a2404/activesupport/lib/active_support/values/time_zone.rb#L76
    UTC_TIME_ZONE_IDENTIFIER = "Etc/UTC"

    # @param time_zone [String]
    #   Must be an unambiguous, valid Rails time zone string or IANA time-zone identifier
    #   according to +ActiveSupport::TimeZone::find_tzinfo+.
    #   See https://github.com/tzinfo/tzinfo/issues/53
    # @param datetime_source [Time, ActiveSupport::TimeWithZone]
    #   A time value from which the time zone will be inferred.
    #   Only considered if no explicit +time_zone+ option is given.
    def initialize(time_zone: nil, datetime_source:)
      @time_zone = time_zone
      @datetime_source = datetime_source
    end

    # Defaults to UTC if no time zone is passed and the datetime source lacks time zone information.
    # @return [String] IANA Time Zone Database identifier
    # @raise [Reprise::InvalidTimeZoneError] if the time zone is ambiguous or invalid.
    def to_s
      return ActiveSupport::TimeZone.find_tzinfo(time_zone).identifier if time_zone
      return datetime_source.time_zone.tzinfo.identifier if datetime_source.is_a?(ActiveSupport::TimeWithZone)

      UTC_TIME_ZONE_IDENTIFIER
    rescue TZInfo::InvalidTimezoneIdentifier
      raise InvalidTimeZoneError, invalid_time_zone_identifier_error
    end

    private

    attr_reader :time_zone, :datetime_source

    def invalid_time_zone_identifier_error
      <<~ERROR
        "#{time_zone}" is not a valid, unambiguous IANA Time Zone Database identifier.
        For more information, see: 
        - https://github.com/tzinfo/tzinfo/issues/53
        - https://github.com/rails/rails/blob/19eebf6d33dd15a0172e3ed2481bec57a89a2404/activesupport/lib/active_support/values/time_zone.rb#L33-L185
      ERROR
    end
  end
end
