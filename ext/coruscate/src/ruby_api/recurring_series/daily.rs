use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, Days, TimeDelta};
use chrono_tz::Tz;

#[derive(Debug, Clone)]
pub(crate) struct Daily {
    pub(crate) series_options: SeriesOptions,
}

impl Daily {
    pub(crate) fn new(series_options: SeriesOptions) -> Daily {
        return Daily { series_options };
    }
}

impl Recurrable for Daily {
    fn get_series_options(&self) -> &SeriesOptions {
        return &self.series_options;
    }

    fn get_time_of_day(&self) -> &TimeOfDay {
        return &self.series_options.time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.series_options.duration_in_seconds;
    }

    fn next_occurrence_candidate(&self, datetime_cursor: &DateTime<Tz>) -> Option<DateTime<Tz>> {
        // > Returns the latest possible result of a time zone mapping.
        // > Returns None if local time falls in a gap in the local time, or if there was an error.
        // https://docs.rs/chrono/latest/chrono/offset/enum.LocalResult.html#method.latest
        // This will have confusing behaviour when a daily series is requested for a time that
        // intermittently falls within a time zone transition (e.g. DST / ST). Whenever possible,
        // we respect the _later_ interpretation of the time, biasing towards the new offset.
        return match datetime_cursor
            .with_time(self.naive_starts_at_time())
            .latest() {
            Some(datetime_cursor) => { Some(datetime_cursor) },
            None => {
                // If there is no local time (e.g. because we're in a time gap,
                // during a DST transition, bypassing that exact hour) we return
                // the cursor alone.
                return Some(datetime_cursor.clone())
            }
        }
    }

    fn advance_datetime_cursor(&self, datetime_cursor: &DateTime<Tz>) -> DateTime<Tz> {
        // If a time zone jumps from 2:00 AM to 3:00 PM for DST,
        // then the local 2:30 AM time simply does not exist; in that scenario,
        // we increment the UTC time and take the local time from that.
        return datetime_cursor.checked_add_days(Days::new(1)).unwrap_or_else(||
            datetime_cursor
                .to_utc()
                .checked_add_signed(TimeDelta::hours(24))
                .unwrap().with_timezone(&datetime_cursor.timezone())
        );
    }
}
