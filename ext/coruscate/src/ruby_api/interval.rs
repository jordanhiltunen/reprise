use crate::ruby_api::traits::HasOverlapAwareness;

pub(crate) struct Interval {
    pub(crate) starts_at_unix_timestamp: i64,
    pub(crate) ends_at_unix_timestamp: i64
}

impl Interval {
    pub(crate) fn new(starts_at_unix_timestamp: i64, ends_at_unix_timestamp: i64) -> Interval {
        return Interval { starts_at_unix_timestamp, ends_at_unix_timestamp }
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
