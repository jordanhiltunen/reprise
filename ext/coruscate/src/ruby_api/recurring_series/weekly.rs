use chrono::{Datelike, DateTime, Days, TimeDelta, Weekday};
use chrono_tz::Tz;
use magnus::Symbol;
use crate::ruby_api::clock::advance_time_safely;
use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::{Recurrable};

#[derive(Debug, Clone)]
pub(crate) struct Weekly {
    pub(crate) weekday: Weekday,
    pub(crate) series_options: SeriesOptions
}

impl Weekly {
    pub(crate) fn new(weekday_symbol: Symbol, series_options: SeriesOptions) -> Weekly {
        let weekday = weekday_symbol.to_string().parse::<Weekday>().unwrap();

        return Weekly {
            weekday,
            series_options
        }
    }
}

impl Recurrable for Weekly {
    fn get_series_options(&self) -> &SeriesOptions {
        return &self.series_options;
    }

    fn next_occurrence_candidate(&self, datetime_cursor: &DateTime<Tz>) -> Option<DateTime<Tz>> {
        return if self.occurrence_candidate_matches_criteria(datetime_cursor) {
            Some(datetime_cursor).cloned()
        } else {
            None
        }
    }

    fn advance_datetime_cursor(&self, datetime_cursor: &DateTime<Tz>) -> DateTime<Tz> {
        // If the current candidate matches the criteria, we can advance by 1-week moving forward.
        return if self.occurrence_candidate_matches_criteria(datetime_cursor) {
            advance_time_safely(datetime_cursor, TimeDelta::days(7), self.naive_starts_at_time())
        } else {
            advance_time_safely(datetime_cursor, TimeDelta::days(1), self.naive_starts_at_time())
        }
    }

    fn occurrence_candidate_matches_criteria(&self, occurrence_candidate: &DateTime<Tz>) -> bool {
        return occurrence_candidate.weekday() == self.weekday;
    }
}
