use chrono::{DateTime, Timelike};
use chrono_tz::Tz;
use magnus::symbol::IntoSymbol;
use magnus::RHash;

#[derive(Debug, Clone)]
pub(crate) struct TimeOfDay {
    pub(crate) hour: u32,
    pub(crate) minute: u32,
    pub(crate) second: u32,
}

impl TimeOfDay {
    pub(crate) fn new_from_ruby_hash(time_of_day: RHash) -> TimeOfDay {
        let ruby = magnus::Ruby::get().unwrap();

        return TimeOfDay {
            hour: time_of_day
                .fetch::<_, u32>("hour".into_symbol_with(&ruby))
                .unwrap_or(0),
            minute: time_of_day
                .fetch::<_, u32>("minute".into_symbol_with(&ruby))
                .unwrap_or(0),
            second: time_of_day
                .fetch::<_, u32>("second".into_symbol_with(&ruby))
                .unwrap_or(0),
        };
    }

    pub(crate) fn new_from_local_time(local_time: DateTime<Tz>) -> TimeOfDay {
        return TimeOfDay {
            hour: local_time.hour(),
            minute: local_time.minute(),
            second: local_time.second(),
        };
    }
}
