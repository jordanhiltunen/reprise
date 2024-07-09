use chrono::{DateTime, Duration, NaiveTime};
use chrono_tz::Tz;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::time_of_day::TimeOfDay;

pub(crate) trait HasOverlapAwareness {
    fn get_starts_at_unix_timestamp(&self) -> i64;
    fn get_ends_at_unix_timestamp(&self) -> i64;

    fn overlaps_with<T: HasOverlapAwareness>(&self, other: &T) -> bool {
        return (self.get_starts_at_unix_timestamp() <= other.get_ends_at_unix_timestamp())
            && (other.get_starts_at_unix_timestamp() < self.get_ends_at_unix_timestamp());
    }
}

pub(crate) trait CustomRecurrable {
    fn generate_occurrences(&self, starts_at: DateTime<Tz>, ends_at: DateTime<Tz>) -> Vec<Occurrence>;
}

// https://stackoverflow.com/a/64298897
pub(crate) trait Recurrable: std::fmt::Debug {
    fn get_series_options(&self) -> &SeriesOptions;
    fn generate_occurrences(&self, starts_at: DateTime<Tz>, ends_at: DateTime<Tz>) -> Vec<Occurrence> {
        let mut occurrences = Vec::new();

        // If the series itself has its own defined bookends, respect those; otherwise, fall back to the
        // bookends passed by the parent schedule.
        let starts_at = self.get_series_options().local_starts_at_datetime().unwrap_or(starts_at);
        let ends_at = self.get_series_options().local_ends_at_datetime().unwrap_or(ends_at);

        return match self.first_occurrence_datetime(&starts_at, &ends_at) {
            None => { occurrences }
            Some(first_occurrence_datetime) => {
                let mut current_occurrence_datetime = first_occurrence_datetime;

                while current_occurrence_datetime < ends_at {
                    occurrences.push(Occurrence {
                        starts_at_unix_timestamp: current_occurrence_datetime.timestamp(),
                        ends_at_unix_timestamp: (current_occurrence_datetime + Duration::seconds(self.get_occurrence_duration_in_seconds())).timestamp()
                    });

                    current_occurrence_datetime = self.next_occurrence_candidate(&current_occurrence_datetime);
                }

                // Only collect every Nth occurrence if an interval has been requested.
                if self.get_series_options().interval > 1 {
                    occurrences.into_iter().step_by(self.get_series_options().interval as usize).collect()
                } else {
                    occurrences
                }
            }
        }
    }

    fn get_time_of_day(&self) -> &TimeOfDay;
    fn get_occurrence_duration_in_seconds(&self) -> i64;

    fn naive_starts_at_time(&self) -> NaiveTime {
        return NaiveTime::from_hms_opt(
            self.get_time_of_day().hour,
            self.get_time_of_day().minute,
            self.get_time_of_day().second,
        ).unwrap();
    }

    fn generate_first_occurrence_candidate(&self, starts_at: &DateTime<Tz>) -> DateTime<Tz> {
        return starts_at.with_time(self.naive_starts_at_time()).unwrap();
    }

    fn occurrence_candidate_matches_criteria(&self, occurrence_candidate: &DateTime<Tz>) -> bool;
    fn advance_to_find_first_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz>;
    fn next_occurrence_candidate(&self, occurrence_candidate: &DateTime<Tz>) -> DateTime<Tz>;

    fn first_occurrence_datetime(&self, starts_at: &DateTime<Tz>, ends_at: &DateTime<Tz>) -> Option<DateTime<Tz>> {
        let mut occurrence_candidate = self.generate_first_occurrence_candidate(starts_at);

        if self.occurrence_candidate_matches_criteria(&occurrence_candidate) &&
            occurrence_candidate > *starts_at &&
            occurrence_candidate < *ends_at {
            return Some(occurrence_candidate)
        } else {
            let mut occurrence_found: bool = false;

            while occurrence_candidate < *ends_at {
                occurrence_candidate = self.advance_to_find_first_occurrence_candidate(&occurrence_candidate);

                if self.occurrence_candidate_matches_criteria(&occurrence_candidate) {
                    occurrence_found = true;
                    break;
                }
            }

            match occurrence_found {
                true => Some(occurrence_candidate),
                false => None,
            }
        }
    }
}
