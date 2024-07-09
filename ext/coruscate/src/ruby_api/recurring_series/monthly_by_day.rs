use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, Datelike, Days, Months};
use chrono_tz::Tz;

#[derive(Debug, Clone)]
pub(crate) struct MonthlyByDay {
    pub(crate) day_number: u32,
    pub(crate) series_options: SeriesOptions,
}

impl MonthlyByDay {
    pub(crate) fn new(day_number: u32, series_options: SeriesOptions) -> MonthlyByDay {
        return MonthlyByDay {
            day_number,
            series_options,
        };
    }
}

impl Recurrable for MonthlyByDay {
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
        occurrence_candidate.day() == self.day_number
    }

    fn advance_to_find_first_occurrence_candidate(
        &self,
        occurrence_candidate: &DateTime<Tz>,
    ) -> DateTime<Tz> {
        // We add days until we hit the desired day number.
        occurrence_candidate
            .checked_add_days(Days::new(1))
            .unwrap()
            .with_time(self.naive_starts_at_time())
            .unwrap()
    }

    fn next_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        occurrence_candidate
            .checked_add_months(Months::new(1))
            .unwrap()
            .with_time(self.naive_starts_at_time())
            .unwrap()
    }
}
