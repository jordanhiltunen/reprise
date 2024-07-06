use crate::ruby_api::traits::HasOverlapAwareness;

#[derive(Debug)]
#[derive(Clone)]
pub(crate) struct Exclusion {
    pub(crate) starts_at_unix_timestamp: i64,
    pub(crate) ends_at_unix_timestamp: i64
}

impl Exclusion {
    pub(crate) fn new(starts_at_unix_timestamp: i64, ends_at_unix_timestamp: i64) -> Exclusion {
        return Exclusion { starts_at_unix_timestamp, ends_at_unix_timestamp }
    }
}

impl HasOverlapAwareness for Exclusion {
    fn get_start_time(&self) -> i64 {
        return self.starts_at_unix_timestamp;
    }

    fn get_end_time(&self) -> i64 {
        return self.ends_at_unix_timestamp;
    }
}
