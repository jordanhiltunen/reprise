use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, Days, Timelike};
use chrono_tz::Tz;

#[derive(Debug, Clone)]
pub(crate) struct Hourly {
    pub(crate) series_options: SeriesOptions,
}

impl Hourly {
    pub(crate) fn new(series_options: SeriesOptions) -> Hourly {
        return Hourly { series_options };
    }
}

impl Recurrable for Hourly {
    fn get_series_options(&self) -> &SeriesOptions {
        return &self.series_options;
    }

    fn get_time_of_day(&self) -> &TimeOfDay {
        return &self.series_options.time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.series_options.duration_in_seconds;
    }

    fn occurrence_candidate_matches_criteria(&self, _occurrence_candidate: &DateTime<Tz>) -> bool {
        // we can essentially no-op for hourly increments; we're not checking for specific
        // characteristics like the day of the week.
        return true;
    }

    fn advance_to_find_first_occurrence_candidate(
        &self,
        occurrence_candidate: &DateTime<Tz>,
    ) -> DateTime<Tz> {
        // same implementation
        return self.next_occurrence_candidate(occurrence_candidate);
    }

    fn next_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        // We can't operate exclusively on DateTime<Tz> values, as it will lead to
        // invalid or ambiguous times when crossing DST / Standard Time transitions.
        // https://docs.rs/chrono/latest/chrono/struct.DateTime.html#method.with_hour
        let utc_occurrence_candidate = occurrence_candidate.to_utc();

        let new_utc_occurrence_candidate = if utc_occurrence_candidate.hour() == 23 {
            utc_occurrence_candidate
                .checked_add_days(Days::new(1))
                .unwrap()
                .with_hour(0)
                .unwrap()
        } else {
            utc_occurrence_candidate
                .with_hour(utc_occurrence_candidate.hour() + 1)
                .unwrap()
        };

        return new_utc_occurrence_candidate.with_timezone(&occurrence_candidate.timezone());
    }
}
