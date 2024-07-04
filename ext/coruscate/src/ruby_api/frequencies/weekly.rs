// on day
// interval (e.g. every other).

use std::cell::RefCell;
use std::cell::Ref;
use chrono::{Datelike, DateTime, Days, Duration, NaiveTime, Weekday};
use chrono_tz::Tz;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::schedule::Schedule;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::RecurringSeries;

#[derive(Debug)]
pub(crate) struct Weekly<'a> {
    pub(crate) schedule: &'a RefCell<Schedule<'a>>,
    pub(crate) weekday: Weekday,
    pub(crate) starts_at_time_of_day: TimeOfDay,
    pub(crate) duration_in_seconds: i64
}

impl Weekly<'_> {
    pub(crate) fn new<'a>(schedule: &'a RefCell<Schedule<'a>>, weekday_string: String, starts_at_time_of_day: TimeOfDay, duration_in_seconds: i64) -> Weekly<'a> {
        let weekday = weekday_string.parse::<Weekday>().unwrap();

        return Weekly {
            schedule,
            weekday,
            starts_at_time_of_day,
            duration_in_seconds,
        }
    }

    fn first_occurrence_datetime(&self) -> Option<DateTime<Tz>> {
        let mut occurrence_candidate = self.generate_first_occurrence_candidate();

        if occurrence_candidate.weekday() == self.weekday &&
        occurrence_candidate > self.borrowed_schedule().local_starts_at &&
        occurrence_candidate < self.borrowed_schedule().local_ends_at {
            return Some(occurrence_candidate);
        } else {
            let mut occurrence_found: bool = false;

            while (occurrence_candidate < self.borrowed_schedule().local_ends_at) {
                occurrence_candidate = occurrence_candidate.checked_add_days(Days::new(1)).unwrap();

               if (occurrence_candidate.weekday() == self.weekday) {
                   occurrence_found = true;
                   break;
               }
            }

            match occurrence_found {
                true => Some(occurrence_candidate),
                false => None,
            }
        }
    }

    fn generate_first_occurrence_candidate(&self) -> DateTime<Tz> {
        return self.borrowed_schedule().local_starts_at.with_time(self.naive_starts_at_time()).unwrap();
    }

    fn naive_starts_at_time(&self) -> NaiveTime {
        return NaiveTime::from_hms_opt(
            self.starts_at_time_of_day.hour,
            self.starts_at_time_of_day.minute,
            self.starts_at_time_of_day.second,
        ).unwrap();
    }

    pub(crate) fn generate_occurrences(&self) -> Vec<Occurrence> {
        let mut occurrences = Vec::new();

        return match self.first_occurrence_datetime() {
            None => { occurrences }
            Some(first_occurrence_datetime) => {
                let mut current_occurrence_datetime = first_occurrence_datetime;

                while current_occurrence_datetime < self.borrowed_schedule().local_ends_at {
                    occurrences.push(Occurrence {
                        start_time: current_occurrence_datetime.timestamp(),
                        end_time: (current_occurrence_datetime + Duration::seconds(self.duration_in_seconds)).timestamp()
                    });

                    current_occurrence_datetime = current_occurrence_datetime.checked_add_days(
                        Days::new(7)).unwrap().with_time(self.naive_starts_at_time()).unwrap();
                }

                occurrences
            }
        }
    }

    fn borrowed_schedule(&self) -> Ref<Schedule> {
        self.schedule.borrow()
    }
}

impl RecurringSeries for Weekly<'_> {
    fn generate_occurrences(&self) -> Vec<Occurrence> {
        let mut occurrences = Vec::new();

        return match self.first_occurrence_datetime() {
            None => { occurrences }
            Some(first_occurrence_datetime) => {
                let mut current_occurrence_datetime = first_occurrence_datetime;

                while current_occurrence_datetime < self.borrowed_schedule().local_ends_at {
                    occurrences.push(Occurrence {
                        start_time: current_occurrence_datetime.timestamp(),
                        end_time: (current_occurrence_datetime + Duration::seconds(self.duration_in_seconds)).timestamp()
                    });

                    current_occurrence_datetime = current_occurrence_datetime.checked_add_days(
                        Days::new(7)).unwrap().with_time(self.naive_starts_at_time()).unwrap();
                }

                occurrences
            }
        }
    }
}
