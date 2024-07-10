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

    fn next_occurrence_candidate(&self, datetime_cursor: &DateTime<Tz>) -> Option<DateTime<Tz>> {
        // no-op; we ensure that every time we advance the cursor, we are doing so to
        // the next valid occurrence.
        return Some(datetime_cursor.clone());
    }

    fn advance_datetime_cursor(&self, datetime_cursor: &DateTime<Tz>) -> DateTime<Tz> {
        // We can't operate exclusively on DateTime<Tz> values, as it will lead to
        // invalid or ambiguous times when crossing DST / Standard Time transitions.
        // https://docs.rs/chrono/latest/chrono/struct.DateTime.html#method.with_hour
        let utc_occurrence_candidate = datetime_cursor.to_utc();

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

        return new_utc_occurrence_candidate.with_timezone(&datetime_cursor.timezone());
    }
}
