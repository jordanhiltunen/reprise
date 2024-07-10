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

    fn next_occurrence_candidate(&self, datetime_cursor: &DateTime<Tz>) -> Option<DateTime<Tz>> {
        return if datetime_cursor.day() == self.day_number {
            Some(datetime_cursor).cloned()
        } else {
            None
        }
    }

    fn advance_datetime_cursor(&self, datetime_cursor: &DateTime<Tz>) -> DateTime<Tz> {
        if datetime_cursor.day() == self.day_number {
            // If the current value already falls on the right day, moving forward
            // we only need to increment by month.
            datetime_cursor
                .checked_add_months(Months::new(1))
                .unwrap()
                .with_time(self.naive_starts_at_time())
                .unwrap()
        } else {
            // If we are not yet on the right day, we need to increment by day
            // TODO: consider using with_day() instead so we don't have to increment.
            datetime_cursor
                .checked_add_days(Days::new(1))
                .unwrap()
                .with_time(self.naive_starts_at_time())
                .unwrap()
        }
    }
}
