use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, TimeDelta};
use chrono_tz::Tz;

#[derive(Debug, Clone)]
pub(crate) struct Minutely {
    pub(crate) series_options: SeriesOptions,
}

impl Minutely {
    pub(crate) fn new(series_options: SeriesOptions) -> Minutely {
        return Minutely { series_options };
    }
}

impl Recurrable for Minutely {
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
        return match datetime_cursor.checked_add_signed(TimeDelta::minutes(1)) {
            None => datetime_cursor
                .to_utc()
                .checked_add_signed(TimeDelta::minutes(1))
                .unwrap()
                .with_timezone(&datetime_cursor.timezone()),
            Some(datetime_cursor) => datetime_cursor,
        };
    }
}
