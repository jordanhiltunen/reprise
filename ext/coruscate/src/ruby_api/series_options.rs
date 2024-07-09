use crate::ruby_api::schedule::UnixTimestamp;
use crate::ruby_api::time_of_day::TimeOfDay;
use chrono::DateTime;
use chrono_tz::Tz;
use magnus::{scan_args, RHash};

#[derive(Clone, Debug)]
pub(crate) struct SeriesOptions {
    time_zone: Tz,
    pub(crate) time_of_day: TimeOfDay,
    pub(crate) duration_in_seconds: i64,
    pub(crate) interval: i64,
    // Callers can specify their own start & end datetime bookends
    // that are applied preferentially over the bookends of the
    // parent schedule itself.
    pub(crate) starts_at_unix_timestamp: Option<UnixTimestamp>,
    pub(crate) ends_at_unix_timestamp: Option<UnixTimestamp>,
}

type RubySeriesOptionsKwargs = (
    RHash,
    i64,
    i64,
    Option<UnixTimestamp>,
    Option<UnixTimestamp>,
);

impl SeriesOptions {
    pub(crate) fn new(time_zone: Tz, kw: RHash) -> SeriesOptions {
        let args: scan_args::KwArgs<RubySeriesOptionsKwargs, (), ()> = scan_args::get_kwargs(
            kw,
            &[
                "time_of_day",
                "duration_in_seconds",
                "interval",
                "starts_at_unix_timestamp",
                "ends_at_unix_timestamp",
            ],
            &[],
        )
        .unwrap();
        let (
            time_of_day,
            duration_in_seconds,
            interval,
            starts_at_unix_timestamp,
            ends_at_unix_timestamp,
        ): RubySeriesOptionsKwargs = args.required;
        let time_of_day = TimeOfDay::new_from_ruby_hash(time_of_day);

        return SeriesOptions {
            time_zone,
            time_of_day,
            duration_in_seconds,
            interval,
            starts_at_unix_timestamp,
            ends_at_unix_timestamp,
        };
    }

    pub fn time_of_day(&self) -> &TimeOfDay {
        return &self.time_of_day;
    }

    pub fn duration_in_seconds(&self) -> i64 {
        return self.duration_in_seconds;
    }

    pub fn interval(&self) -> i64 {
        return self.interval;
    }

    pub fn local_starts_at_datetime(&self) -> Option<DateTime<Tz>> {
        return match self.starts_at_unix_timestamp {
            None => None,
            Some(starts_at_unix_timestamp) => {
                let starts_at_utc = DateTime::from_timestamp(starts_at_unix_timestamp, 0).unwrap();
                Some(starts_at_utc.with_timezone(&self.time_zone))
            }
        };
    }

    pub fn local_ends_at_datetime(&self) -> Option<DateTime<Tz>> {
        return match self.ends_at_unix_timestamp {
            None => None,
            Some(ends_at_unix_timestamp) => {
                let ends_at_utc = DateTime::from_timestamp(ends_at_unix_timestamp, 0).unwrap();
                Some(ends_at_utc.with_timezone(&self.time_zone))
            }
        };
    }
}
