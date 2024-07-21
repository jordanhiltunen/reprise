use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, TimeDelta};
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
        return match datetime_cursor.checked_add_signed(TimeDelta::hours(1)) {
            None => datetime_cursor
                .to_utc()
                .checked_add_signed(TimeDelta::hours(1))
                .unwrap()
                .with_timezone(&datetime_cursor.timezone()),
            Some(datetime_cursor) => datetime_cursor,
        };
    }
}
