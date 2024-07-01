use crate::ruby_api::occurrence::Occurrence;

pub(crate) trait HasOverlapAwareness {
    fn get_start_time(&self) -> i64;
    fn get_end_time(&self) -> i64;

    fn overlaps_with<T: HasOverlapAwareness>(&self, other: &T) -> bool {
        return (self.get_start_time() <= other.get_end_time())
            && (other.get_start_time() < self.get_end_time());
    }
}

pub(crate) trait RecurrenceRule {
    fn generate_occurrences(&self) -> Vec<Occurrence>;
}
