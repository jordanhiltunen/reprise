# frozen_string_literal: true

module Reprise
  module Core
    # An Occurrence represents a single instance of a recurring series belong to a schedule.
    #
    # @private This class definition is open-classed only for the purposes
    # of adding documentation; it is defined dynamically within
    # the Rust extension.
    class Occurrence
      # @!attribute [r] starts_at
      #   @return [Time] The start time of the occurrence, given in the current system time zone.
      # @!attribute [r] ends_at
      #   @return [Time] The end time of the occurrence, given in the current system time zone.
      # @!attribute [r] label
      #   @return [String, nil] The label given to the recurring series from which the
      #     occurrence was generated (if present). Can be used to disambiguate occurrences
      #     from different series after generating the schedule's occurrences.
    end
  end
end
