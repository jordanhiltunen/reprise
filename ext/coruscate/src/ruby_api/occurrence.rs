use crate::ruby_api::traits::HasOverlapAwareness;

pub(crate) struct Occurrence {
    pub(crate) start_time: i64,
    pub(crate) end_time: i64
}

impl Occurrence {
    pub(crate) fn new(start_time: i64, end_time: i64) -> Occurrence {
        return Occurrence { start_time, end_time }
    }
}

impl HasOverlapAwareness for Occurrence {
    fn get_start_time(&self) -> i64 {
        return self.start_time;
    }

    fn get_end_time(&self) -> i64 {
        return self.end_time;
    }
}
