use chrono::{Datelike, DateTime, Days, Weekday};
use chrono_tz::Tz;
use magnus::Symbol;
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

    fn get_time_of_day(&self) -> &TimeOfDay {
        return &self.series_options.time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.series_options.duration_in_seconds;
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
