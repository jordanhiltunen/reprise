use chrono::{Datelike, DateTime, Days, Duration, NaiveTime, Weekday};
use chrono_tz::Tz;
use magnus::Symbol;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::{CustomRecurrable, Recurrable};

#[derive(Debug, Clone)]
pub(crate) struct MonthlyByNthWeekday {
    pub(crate) weekday: Weekday,
    pub(crate) nth_weekday: i32,
    pub(crate) series_options: SeriesOptions,
}

impl MonthlyByNthWeekday {
    pub(crate) fn new(weekday_symbol: Symbol, nth_weekday: i32, series_options: SeriesOptions) -> MonthlyByNthWeekday {
        let weekday = weekday_symbol.to_string().parse::<Weekday>().expect("Weekday must parse successfully");

        return MonthlyByNthWeekday {
            weekday,
            nth_weekday,
            series_options
        }
    }

    fn identify_all_weekdays_in_month_of(&self, &datetime: &DateTime<Tz>) -> Vec<DateTime<Tz>> {
        let mut weekdays_in_month: Vec<DateTime<Tz>> = Vec::new();
        let start_of_month = datetime.with_day(1).unwrap().with_time(self.naive_starts_at_time()).unwrap();
        let end_of_month: DateTime<Tz> = self.beginning_of_next_month_from(&start_of_month);

        let mut examined_datetime = start_of_month;

        // Set the cursor to the first day in the month with the requested weekday.
        while examined_datetime < end_of_month {
            if examined_datetime.weekday() == self.weekday {
                break;
            }

            examined_datetime = examined_datetime
                .checked_add_days(Days::new(1)).unwrap()
                .with_time(self.naive_starts_at_time()).unwrap()
        }

        // Push the day and all remaining days with the same weekday into the collection.
        while examined_datetime < end_of_month {
            weekdays_in_month.push(examined_datetime);

            examined_datetime = examined_datetime.checked_add_days(Days::new(7)).unwrap()
                .with_time(self.naive_starts_at_time()).unwrap();
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
        }
    }

    fn get_time_of_day(&self) -> &TimeOfDay {
        return &self.series_options.time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.series_options.duration_in_seconds;
    }

    fn naive_starts_at_time(&self) -> NaiveTime {
        return NaiveTime::from_hms_opt(
            self.get_time_of_day().hour,
            self.get_time_of_day().minute,
            self.get_time_of_day().second,
        ).unwrap();
    }

    fn beginning_of_next_month_from(&self, datetime: &DateTime<Tz>) -> DateTime<Tz> {
        return if datetime.month() == 12 {
            datetime
                .with_year(datetime.year() + 1).expect("Datetime must advance to the next year")
                .with_month(1).expect("Datetime must be set to January")
                .with_day(1).expect("Datetime must be set to the first day of the month ")
        } else {
            datetime
                .with_month(datetime.month() + 1).expect("Datetime must advance to the next month")
                .with_day(1).expect("Datetime must be set to the first of the month")
        };
    }
}

impl CustomRecurrable for MonthlyByNthWeekday {
    // We override the trait definition because the logic required to expand this recurring series
    // differs substantially from the others.
    fn generate_occurrences(&self, starts_at: DateTime<Tz>, ends_at: DateTime<Tz>) -> Vec<Occurrence> {
        let mut occurrences = Vec::new();
        let mut current_examined_datetime = starts_at;

        while current_examined_datetime < ends_at {
            let current_weekdays_in_examined_month = self.identify_all_weekdays_in_month_of(&current_examined_datetime);

            match current_weekdays_in_examined_month.get(
                self.get_unsigned_nth_weekday_index_from_signed(current_weekdays_in_examined_month.len() as i32)
            ) {
                None => {}
                Some(series_match) => {
                    if *series_match > starts_at && *series_match < ends_at {
                        occurrences.push(Occurrence {
                            starts_at_unix_timestamp: series_match.timestamp(),
                            ends_at_unix_timestamp: (*series_match + Duration::seconds(self.get_occurrence_duration_in_seconds())).timestamp()
                        });
                    }
                }
            }

            current_examined_datetime = self.beginning_of_next_month_from(&current_examined_datetime);
        }

        occurrences
    }
}
