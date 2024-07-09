use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, Days};
use chrono_tz::Tz;
use crate::ruby_api::series_options::SeriesOptions;

#[derive(Debug, Clone)]
pub(crate) struct Daily {
    pub(crate) series_options: SeriesOptions
}

impl Daily {
    pub(crate) fn new(series_options: SeriesOptions) -> Daily {
        return Daily {
            series_options
        };
    }
}

impl Recurrable for Daily {
    fn get_series_options(&self) -> &SeriesOptions {
        return &self.series_options
    }

    fn get_time_of_day(&self) -> &TimeOfDay {
        return &self.series_options.time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.series_options.duration_in_seconds;
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
