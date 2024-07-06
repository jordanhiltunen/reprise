use chrono::{Datelike, DateTime, Days, Months, Weekday};
use chrono_tz::Tz;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::RecurringSeries;

#[derive(Debug, Clone)]
pub(crate) struct MonthlyByNthWeekday {
    pub(crate) weekday: Weekday,
    pub(crate) nth_weekday: i32,
    pub(crate) starts_at_time_of_day: TimeOfDay,
    pub(crate) duration_in_seconds: i64,
}

impl MonthlyByNthWeekday {
    pub(crate) fn new(weekday_string: String, nth_weekday: i32, starts_at_time_of_day: TimeOfDay, duration_in_seconds: i64) -> MonthlyByNthWeekday {
        let weekday = weekday_string.parse::<Weekday>().unwrap();

        return MonthlyByNthWeekday {
            weekday,
            nth_weekday,
            starts_at_time_of_day,
            duration_in_seconds
        }
    }

    fn get_all_weekdays_in_month_of(&self, &datetime: &DateTime<Tz>) -> Vec<DateTime<Tz>> {
        let mut weekdays_in_month: Vec<DateTime<Tz>> = Vec::new();
        let start_of_month = datetime.with_day(1).unwrap().with_time(self.naive_starts_at_time()).unwrap();

        // TODO: examine bookend edge cases
        let end_of_month: DateTime<Tz> = if start_of_month.month() == 12 {
            start_of_month.with_year(start_of_month.year() + 1).unwrap().with_month(1).unwrap()
        } else {
            start_of_month.with_month(datetime.month() + 1).unwrap()
        };

        let mut examined_datetime = start_of_month;

        // Set the cursor to the first day in the month with the requested weekday.
        while examined_datetime < end_of_month {
            if examined_datetime.weekday() == self.weekday {
                break;
            }

            examined_datetime = examined_datetime.checked_add_days(Days::new(1)).unwrap().
                with_time(self.naive_starts_at_time()).unwrap();
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
}

impl RecurringSeries for MonthlyByNthWeekday {
    fn get_starts_at_time_of_day(&self) -> &TimeOfDay {
        return &self.starts_at_time_of_day;
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.duration_in_seconds;
    }

    fn generate_first_occurrence_candidate(&self, starts_at: &DateTime<Tz>) -> DateTime<Tz> {
        let weekdays_in_month = self.get_all_weekdays_in_month_of(starts_at);

        let first_occurrence_candidate = weekdays_in_month.get(
            self.get_unsigned_nth_weekday_index_from_signed(weekdays_in_month.len() as i32)
        );

        return first_occurrence_candidate.unwrap().clone()
    }

    // fn generate_first_occurrence_candidate(&self, starts_at: &DateTime<Tz>) -> Option<DateTime<Tz>> {
    //     let weekdays_in_month = self.get_all_weekdays_in_month_of(starts_at);
    //
    //     let first_occurrence_candidate = weekdays_in_month.get(
    //         self.get_unsigned_nth_weekday_index_from_signed(weekdays_in_month.len() as i32)
    //     );
    //
    //     return if first_occurrence_candidate.is_some() {
    //         Some(first_occurrence_candidate.unwrap().clone())
    //     } else {
    //         None
    //     }
    // }
    
    fn occurrence_candidate_matches_criteria(&self, _occurrence_candidate: &DateTime<Tz>) -> bool {
        // no-op; we are handling more of the criteria in earlier steps.
        true
    }

    fn advance_to_find_first_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        // no-op.
        self.generate_first_occurrence_candidate(occurrence_candidate)
    }

    // fn advance_to_find_first_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> Option<DateTime<Tz>> {
    //     // no-op.
    //     self.generate_first_occurrence_candidate(occurrence_candidate)
    // }

    fn next_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz> {
        let occurrence_candidate = occurrence_candidate.checked_add_months(Months::new(1)).unwrap();
        let weekdays_in_month = self.get_all_weekdays_in_month_of(&occurrence_candidate);

        return weekdays_in_month[self.get_unsigned_nth_weekday_index_from_signed(weekdays_in_month.len() as i32)];
    }
}
