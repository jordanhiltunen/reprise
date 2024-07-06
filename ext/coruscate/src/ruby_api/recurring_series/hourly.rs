use chrono::{DateTime, Timelike};
use chrono_tz::Tz;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::{RecurringSeries};

#[derive(Debug, Clone)]
pub(crate) struct Hourly {
    pub(crate) starts_at_time_of_day: TimeOfDay,
    pub(crate) duration_in_seconds: i64
}

impl Hourly {
    pub(crate) fn new(starts_at_time_of_day: TimeOfDay, duration_in_seconds: i64) -> Hourly {
        return Hourly {
            starts_at_time_of_day,
            duration_in_seconds,
        }
    }
}

impl RecurringSeries for Hourly {
    fn get_starts_at_time_of_day(&self) -> &TimeOfDay {
        return &self.starts_at_time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.duration_in_seconds;
    }

    fn occurrence_candidate_matches_criteria(&self, _occurrence_candidate: &DateTime<Tz>) -> bool {
        // we can essentially no-op for hourly increments; we're not checking for specific
        // characteristics like the day of the week.
        return true;
    }

    fn advance_to_find_first_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        // TODO: this may panic; investigate further:
        // > Returns None if:
        //
        // > The value for hour is invalid.
        // > The local time at the resulting date does not exist or is ambiguous, for example during a daylight saving time transition.
        // https://docs.rs/chrono/latest/chrono/struct.DateTime.html#method.with_hour
        return occurrence_candidate.with_hour(occurrence_candidate.hour() + 1).unwrap();
    }

    fn next_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        // same implementation
        return self.advance_to_find_first_occurrence_candidate(occurrence_candidate);
    }
}
