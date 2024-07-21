use crate::ruby_api::exclusion::Exclusion;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::traits::HasOverlapAwareness;

#[derive(Debug)]
pub(crate) struct SortedExclusions {
    pub(crate) exclusions: Vec<Exclusion>,
}

impl SortedExclusions {
    pub(crate) fn new() -> SortedExclusions {
        return SortedExclusions {
            exclusions: Vec::new(),
        };
    }

    pub(crate) fn add_exclusion(&mut self, exclusion: Exclusion) {
        self.exclusions.push(exclusion);
        self.reorder_exclusions();
    }

    pub(crate) fn add_exclusions(&mut self, exclusions: &mut Vec<Exclusion>) {
        self.exclusions.append(exclusions);
        self.reorder_exclusions();
    }

    pub(crate) fn is_occurrence_excluded(&self, occurrence: &Occurrence) -> bool {
        return self.exclusions.iter().any(|e| e.overlaps_with(occurrence));
    }

    fn reorder_exclusions(&mut self) {
        // Maintain an ascending end time sort order to simplify comparisons
        // against occurrences.
        self.exclusions.sort_by_key(|e| e.ends_at_unix_timestamp)
    }
}
