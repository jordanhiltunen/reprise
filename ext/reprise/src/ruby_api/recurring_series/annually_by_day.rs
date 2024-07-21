use crate::ruby_api::clock::{set_datetime_cursor_safely};
use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, Datelike, TimeDelta};
use chrono_tz::Tz;

#[derive(Debug, Clone)]
pub(crate) struct AnnuallyByDay {
    pub(crate) day_number: u32,
    pub(crate) series_options: SeriesOptions,
}

impl AnnuallyByDay {
    pub(crate) fn new(day_number: u32, series_options: SeriesOptions) -> AnnuallyByDay {
        return AnnuallyByDay {
            day_number,
            series_options,
        };
    }

    fn safely_advance_one_year(&self, datetime_cursor: &DateTime<Tz>) -> DateTime<Tz> {
        return match datetime_cursor.with_year(datetime_cursor.year() + 1) {
            None => {
                // If we can't advance one year, then we've fallen in a gap, like a leap year.
                // Advance by one day to get out.
                datetime_cursor.to_utc().checked_add_signed(TimeDelta::days(1))
                    .expect("UTC datetime should advance by one day")
                    .with_year(datetime_cursor.year() + 1)
                    .expect("UTC year should advance by one")
                    .with_timezone(&datetime_cursor.timezone())
            }
            Some(new_datetime_cursor) => {
                // If we have advanced by one year, it's still possible that our requested time
                // could fall in a local time gap / ambiguous time, so we still have to be cautious.
                let new_cursor = set_datetime_cursor_safely(
                    new_datetime_cursor.with_timezone(&datetime_cursor.timezone()),
                    self.naive_starts_at_time());

                return new_cursor;
            }
        }
    }
}

impl Recurrable for AnnuallyByDay {
    fn get_series_options(&self) -> &SeriesOptions {
        return &self.series_options;
    }

    fn next_occurrence_candidate(&self, datetime_cursor: &DateTime<Tz>) -> Option<DateTime<Tz>> {
        return if datetime_cursor.ordinal() == self.day_number {
            Some(datetime_cursor).cloned()
        } else {
            None
        };
    }

    fn advance_datetime_cursor(&self, datetime_cursor: &DateTime<Tz>) -> DateTime<Tz> {
        return if datetime_cursor.ordinal() == self.day_number {
            self.safely_advance_one_year(datetime_cursor)
        } else {
            // N.B. This is probably inefficient, advancing by a single day.
            // We could probably do better by determining the exact next day number
            // we could safely advance to (e.g. if it's 366 requested, + 1; 365, 0, etc.)
            let next_day =  datetime_cursor.with_ordinal(self.day_number).unwrap_or_else(||
                            datetime_cursor
                                .to_utc()
                                .checked_add_signed(TimeDelta::days(1))
                                .expect("Datetime should advance by one day")
                                .with_timezone(&datetime_cursor.timezone()));

            return set_datetime_cursor_safely(next_day, self.naive_starts_at_time());
        }
    }
}
