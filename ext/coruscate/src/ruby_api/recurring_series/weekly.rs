use chrono::{Datelike, DateTime, Days, Weekday};
use chrono_tz::Tz;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::{Recurrable};

#[derive(Debug, Clone)]
pub(crate) struct Weekly {
    pub(crate) weekday: Weekday,
    pub(crate) starts_at_time_of_day: TimeOfDay,
    pub(crate) duration_in_seconds: i64
}

impl Weekly {
    pub(crate) fn new(weekday_string: String, starts_at_time_of_day: TimeOfDay, duration_in_seconds: i64) -> Weekly {
        let weekday = weekday_string.parse::<Weekday>().unwrap();

        return Weekly {
            weekday,
            starts_at_time_of_day,
            duration_in_seconds,
        }
    }
}

impl Recurrable for Weekly {
    fn get_starts_at_time_of_day(&self) -> &TimeOfDay {
        return &self.starts_at_time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.duration_in_seconds;
    }

    fn occurrence_candidate_matches_criteria(&self, occurrence_candidate: &DateTime<Tz>) -> bool {
        return occurrence_candidate.weekday() == self.weekday;
    }

    fn advance_to_find_first_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        occurrence_candidate.checked_add_days(Days::new(1)).
            unwrap().with_time(self.naive_starts_at_time()).unwrap()
    }

    fn next_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        occurrence_candidate.checked_add_days(Days::new(7)).
            unwrap().with_time(self.naive_starts_at_time()).unwrap()
    }
}
