use chrono::{DateTime, NaiveTime};
use chrono_tz::Tz;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::time_of_day::TimeOfDay;

pub(crate) trait HasOverlapAwareness {
    fn get_start_time(&self) -> i64;
    fn get_end_time(&self) -> i64;

    fn overlaps_with<T: HasOverlapAwareness>(&self, other: &T) -> bool {
        return (self.get_start_time() <= other.get_end_time())
            && (other.get_start_time() < self.get_end_time());
    }
}

// https://stackoverflow.com/a/64298897
pub(crate) trait RecurringSeries: std::fmt::Debug {
    fn generate_occurrences(&self, starts_at: DateTime<Tz>, ends_at: DateTime<Tz>) -> Vec<Occurrence>;

    fn get_starts_at_time_of_day(&self) -> &TimeOfDay;

    fn naive_starts_at_time(&self) -> NaiveTime {
        return NaiveTime::from_hms_opt(
            self.get_starts_at_time_of_day().hour,
            self.get_starts_at_time_of_day().minute,
            self.get_starts_at_time_of_day().second,
        ).unwrap();
    }
}
