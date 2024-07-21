use crate::ruby_api::clock::advance_time_safely;
use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::traits::Recurrable;
use chrono::{DateTime, Datelike, Months, TimeDelta, Weekday};
use chrono_tz::Tz;
use magnus::Symbol;

#[derive(Debug, Clone)]
pub(crate) struct MonthlyByNthWeekday {
    pub(crate) weekday: Weekday,
    pub(crate) nth_weekday: i32,
    pub(crate) series_options: SeriesOptions,
}

impl MonthlyByNthWeekday {
    pub(crate) fn new(
        weekday_symbol: Symbol,
        nth_weekday: i32,
        series_options: SeriesOptions,
    ) -> MonthlyByNthWeekday {
        let weekday = weekday_symbol
            .to_string()
            .parse::<Weekday>()
            .expect("Weekday should parse successfully");

        return MonthlyByNthWeekday {
            weekday,
            nth_weekday,
            series_options,
        };
    }

    fn identify_all_weekdays_in_month_of(&self, datetime: &DateTime<Tz>) -> Vec<DateTime<Tz>> {
        let mut weekdays_in_month: Vec<DateTime<Tz>> = Vec::new();
        let start_of_month = self.start_of_month_from(datetime);
        let end_of_month: DateTime<Tz> = self.beginning_of_next_month_from(&start_of_month);

        let mut examined_datetime = start_of_month;

        // Set the cursor to the first day in the month with the requested weekday.
        while examined_datetime < end_of_month {
            if examined_datetime.weekday() == self.weekday {
                break;
            }

            examined_datetime = advance_time_safely(
                &examined_datetime,
                TimeDelta::days(1),
                self.naive_starts_at_time(),
            );
        }

        // Push the day and all remaining days with the same weekday into the collection.
        while examined_datetime < end_of_month {
            weekdays_in_month.push(examined_datetime);

            examined_datetime = advance_time_safely(
                &examined_datetime,
                TimeDelta::days(7),
                self.naive_starts_at_time(),
            );
        }

        return weekdays_in_month;
    }

    fn get_unsigned_nth_weekday_index_from_signed(&self, collection_size: i32) -> usize {
        return if self.nth_weekday >= 0 {
            // Return the request nth weekday index if positive.
            self.nth_weekday as usize
        } else {
            // TODO: if the index is STILL negative (imagine indexing -7 into a collection of four
            // elements) then we should panic. A slice access of -4, for example, makes very little
            // sense relative to something like 1, or 2.
            (collection_size - self.nth_weekday.abs()) as usize
        };
    }

    fn beginning_of_next_month_from(&self, datetime: &DateTime<Tz>) -> DateTime<Tz> {
        return if datetime.month() == 12 {
            datetime
                .with_year(datetime.year() + 1)
                .expect("Datetime should advance to the next year")
                .with_month(1)
                .expect("Datetime should be set to January")
                .with_day(1)
                .expect("Datetime should be set to the first day of the month")
        } else {
            match datetime.checked_add_months(Months::new(1)) {
                None => datetime
                    .to_utc()
                    .checked_add_months(Months::new(1))
                    .expect("Datetime should advance by one month")
                    .with_timezone(&datetime.timezone())
                    .with_day(1)
                    .expect("Datetime should be set to the first day of the month"),
                Some(datetime) => datetime
                    .with_day(1)
                    .expect("Datetime should be set to the first of the month"),
            }
        };
    }

    fn start_of_month_from(&self, datetime: &DateTime<Tz>) -> DateTime<Tz> {
        return datetime
            .with_day(1) // TODO: could this panic if the first falls on a DST / ST transition
            .expect("Datetime should be set to the first day of the month")
            .with_time(self.naive_starts_at_time())
            .latest()
            .expect("Datetime should be set to the requested time of day");
    }
}

impl Recurrable for MonthlyByNthWeekday {
    fn get_series_options(&self) -> &SeriesOptions {
        return &self.series_options;
    }

    fn next_occurrence_candidate(&self, datetime_cursor: &DateTime<Tz>) -> Option<DateTime<Tz>> {
        let current_weekdays_in_examined_month =
            self.identify_all_weekdays_in_month_of(&datetime_cursor);

        return current_weekdays_in_examined_month
            .get(self.get_unsigned_nth_weekday_index_from_signed(
                current_weekdays_in_examined_month.len() as i32,
            ))
            .cloned();
    }

    fn advance_datetime_cursor(&self, datetime_cursor: &DateTime<Tz>) -> DateTime<Tz> {
        return self.beginning_of_next_month_from(&datetime_cursor);
    }
}
