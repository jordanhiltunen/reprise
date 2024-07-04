use chrono::{Datelike, DateTime, Days, Duration, NaiveTime, Weekday};
use chrono_tz::Tz;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::time_of_day::TimeOfDay;
use crate::ruby_api::traits::{HasOverlapAwareness, RecurringSeries};

#[derive(Debug)]
pub(crate) struct Weekly {
    pub(crate) weekday: Weekday,
    pub(crate) starts_at_time_of_day: TimeOfDay,
    pub(crate) duration_in_seconds: i64
}

impl Weekly {
    pub(crate) fn new(weekday_string: String, starts_at_time_of_day: TimeOfDay, duration_in_seconds: i64) -> Weekly {
        let weekday = weekday_string.parse::<Weekday>().unwrap();

        return Weekly {
            weekday,
            starts_at_time_of_day,
            duration_in_seconds,
        }
    }

    fn first_occurrence_datetime(&self, starts_at: &DateTime<Tz>, ends_at: &DateTime<Tz>) -> Option<DateTime<Tz>> {
        let mut occurrence_candidate = self.generate_first_occurrence_candidate(&starts_at);

        if occurrence_candidate.weekday() == self.weekday &&
        occurrence_candidate > *starts_at &&
        occurrence_candidate < *ends_at {
            return Some(occurrence_candidate);
        } else {
            let mut occurrence_found: bool = false;

            while occurrence_candidate < *ends_at {
                occurrence_candidate = occurrence_candidate.checked_add_days(Days::new(1)).unwrap();

               if occurrence_candidate.weekday() == self.weekday {
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

    fn generate_first_occurrence_candidate(&self, starts_at: &DateTime<Tz>) -> DateTime<Tz> {
        return starts_at.with_time(self.naive_starts_at_time()).unwrap();
    }
}

impl RecurringSeries for Weekly {
    fn generate_occurrences(&self, starts_at: DateTime<Tz>, ends_at: DateTime<Tz>) -> Vec<Occurrence> {
        let mut occurrences = Vec::new();

        return match self.first_occurrence_datetime(&starts_at, &ends_at) {
            None => { occurrences }
            Some(first_occurrence_datetime) => {
                let mut current_occurrence_datetime = first_occurrence_datetime;

                while current_occurrence_datetime < ends_at {
                    occurrences.push(Occurrence {
                        start_time: current_occurrence_datetime.timestamp(),
                        end_time: (current_occurrence_datetime + Duration::seconds(self.duration_in_seconds)).timestamp()
                    });

                    current_occurrence_datetime = current_occurrence_datetime.checked_add_days(Days::new(7)).
                    unwrap().with_time(self.naive_starts_at_time()).unwrap();
                }

                occurrences
            }
        }
    }

    fn get_starts_at_time_of_day(&self) -> &TimeOfDay {
        return &self.starts_at_time_of_day;
    }
}
