use crate::ruby_api::traits::HasOverlapAwareness;
use chrono::DateTime;
use chrono_tz::Tz;

pub(crate) struct Interval {
    pub(crate) starts_at_unix_timestamp: i64,
    pub(crate) ends_at_unix_timestamp: i64,
    pub(crate) time_zone: Tz,
    pub(crate) starts_at: DateTime<Tz>,
    pub(crate) ends_at: DateTime<Tz>,
}

impl Interval {
    pub(crate) fn new(
        starts_at_unix_timestamp: i64,
        ends_at_unix_timestamp: i64,
        time_zone: Tz,
    ) -> Interval {
        return Interval {
            starts_at_unix_timestamp,
            ends_at_unix_timestamp,
            time_zone,
            starts_at: Self::datetime_from_unix_timestamp(starts_at_unix_timestamp, &time_zone),
            ends_at: Self::datetime_from_unix_timestamp(ends_at_unix_timestamp, &time_zone),
        };
    }

    fn datetime_from_unix_timestamp(unix_timestamp: i64, time_zone: &Tz) -> DateTime<Tz> {
        return DateTime::from_timestamp(unix_timestamp, 0)
            .expect("Unix timestamp must be parsed into a DateTime")
            .with_timezone(time_zone);
    }

    pub(crate) fn starts_at(&self) -> DateTime<Tz> {
        return self.starts_at;
    }

    pub(crate) fn ends_at(&self) -> DateTime<Tz> {
        return self.ends_at;
    }
}

impl HasOverlapAwareness for Interval {
    fn get_starts_at_unix_timestamp(&self) -> i64 {
        return self.starts_at_unix_timestamp;
    }

    fn get_ends_at_unix_timestamp(&self) -> i64 {
        return self.ends_at_unix_timestamp;
    }
}
