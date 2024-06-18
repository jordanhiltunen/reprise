use crate::ruby_api::traits::HasOverlapAwareness;

#[derive(Debug)]
#[derive(Clone)]
pub(crate) struct Exclusion {
    pub(crate) start_time: i64,
    pub(crate) end_time: i64
}

impl Exclusion {
    pub(crate) fn new(start_time: i64, end_time: i64) -> Exclusion {
        return Exclusion { start_time, end_time }
    }
}

impl HasOverlapAwareness for Exclusion {
    fn get_start_time(&self) -> i64 {
        return self.start_time;
    }

    fn get_end_time(&self) -> i64 {
        return self.end_time;
    }
}
