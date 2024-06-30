use chrono::{DateTime, Timelike};
use chrono_tz::Tz;
use magnus::RHash;

pub(crate) struct TimeOfDay {
    pub(crate) hour: u32,
    pub(crate) minute: u32,
    pub(crate) second: u32,
    pub(crate) millisecond: i64
}

impl TimeOfDay {
    pub(crate) fn new_from_ruby_hash(time_of_day: RHash) -> TimeOfDay {
        return TimeOfDay {
            hour: time_of_day.fetch::<_, u32>("hour").unwrap_or(0),
            minute: time_of_day.fetch::<_, u32>("minute").unwrap_or(0),
            second: time_of_day.fetch::<_, u32>("second").unwrap_or(0),
            millisecond: time_of_day.fetch::<_, i64>("millisecond").unwrap_or(0),
        }
    }

    pub(crate) fn new_from_local_time(local_time: DateTime<Tz>) -> TimeOfDay {
        return TimeOfDay {
            hour: local_time.hour(),
            minute: local_time.minute(),
            second: local_time.second(),
            millisecond: local_time.timestamp_millis()
        }
    }
}
