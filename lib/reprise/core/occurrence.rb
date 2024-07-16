# frozen_string_literal: true

module Reprise
  module Core
    # This class definition is open-classed only for the purposes
    # of adding documentation; it is defined dynamically within
    # the Rust extension.
    class Occurrence
      # @!attribute [r] start_time
      #   @return [Time] The start time of the occurrence, given in the current system time zone.
      # @!attribute [r] end_time
      #   @return [Time] The end time of the occurrence, given in the current system time zone.
      # @!attribute [r] label
      #   @return [String, nil] The label given to the recurring series from which the
      #     occurrence was generated (if present). Can be used to disambiguate occurrences
      #     from different series after generating the schedule's occurrences.
    end
  end
end
