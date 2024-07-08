use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, Days};
use chrono_tz::Tz;

#[derive(Debug, Clone)]
pub(crate) struct Daily {
    pub(crate) time_of_day: TimeOfDay,
    pub(crate) duration_in_seconds: i64,
}

impl Daily {
    pub(crate) fn new(time_of_day: TimeOfDay, duration_in_seconds: i64) -> Daily {
        return Daily {
            time_of_day,
            duration_in_seconds,
        };
    }
}

impl Recurrable for Daily {
    fn get_time_of_day(&self) -> &TimeOfDay {
        return &self.time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.duration_in_seconds;
    }

    fn occurrence_candidate_matches_criteria(&self, _occurrence_candidate: &DateTime<Tz>) -> bool {
        // no-op; criteria is uncomplicated, we just advance by one day.
        true
    }

    fn advance_to_find_first_occurrence_candidate(
        &self,
        occurrence_candidate: &DateTime<Tz>,
    ) -> DateTime<Tz> {
        return occurrence_candidate
            .with_time(self.naive_starts_at_time())
            .unwrap();
    }

    fn next_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        return occurrence_candidate
            .checked_add_days(Days::new(1))
            .expect("Datetime must advance by one day")
            .with_time(self.naive_starts_at_time())
            .unwrap();
    }
}
