use crate::ruby_api::clock::set_datetime_cursor_safely;
use crate::ruby_api::occurrence::Occurrence;
use crate::ruby_api::recurring_series::annually_by_day::AnnuallyByDay;
use crate::ruby_api::recurring_series::daily::Daily;
use crate::ruby_api::recurring_series::hourly::Hourly;
use crate::ruby_api::recurring_series::minutely::Minutely;
use crate::ruby_api::recurring_series::monthly_by_day::MonthlyByDay;
use crate::ruby_api::recurring_series::monthly_by_nth_weekday::MonthlyByNthWeekday;
use crate::ruby_api::recurring_series::weekly::Weekly;
use crate::ruby_api::series_options::SeriesOptions;
use crate::ruby_api::time_of_day::TimeOfDay;
use chrono::{DateTime, Duration, NaiveTime};
use chrono_tz::Tz;
use enum_dispatch::enum_dispatch;

pub(crate) trait HasOverlapAwareness {
    fn get_starts_at_unix_timestamp(&self) -> i64;
    fn get_ends_at_unix_timestamp(&self) -> i64;

    fn overlaps_with<T: HasOverlapAwareness>(&self, other: &T) -> bool {
        return (self.get_starts_at_unix_timestamp() < other.get_ends_at_unix_timestamp())
            && (other.get_starts_at_unix_timestamp() < self.get_ends_at_unix_timestamp());
    }

    fn contains<T: HasOverlapAwareness>(&self, other: &T) -> bool {
        return (self.get_starts_at_unix_timestamp() <= other.get_starts_at_unix_timestamp())
            && (self.get_ends_at_unix_timestamp() >= other.get_ends_at_unix_timestamp());
    }
}

#[enum_dispatch]
#[derive(Debug)]
pub enum RecurringSeries {
    Minutely,
    Hourly,
    Daily,
    Weekly,
    MonthlyByDay,
    MonthlyByNthWeekday,
    AnnuallyByDay
}

#[enum_dispatch(RecurringSeries)]
pub(crate) trait Recurrable: std::fmt::Debug {
    fn get_series_options(&self) -> &SeriesOptions;

    fn get_time_of_day(&self) -> &TimeOfDay {
        return self.get_series_options().time_of_day();
    }

    fn get_occurrence_duration_in_seconds(&self) -> i64 {
        return self.get_series_options().duration_in_seconds;
    }

    fn naive_starts_at_time(&self) -> NaiveTime {
        return NaiveTime::from_hms_opt(
            self.get_time_of_day().hour,
            self.get_time_of_day().minute,
            self.get_time_of_day().second,
        )
        .unwrap();
    }

    fn generate_occurrences(
        &self,
        starts_at: DateTime<Tz>,
        ends_at: DateTime<Tz>,
    ) -> Vec<Occurrence> {
        let mut occurrences = Vec::new();

        // If the series itself has its own defined bookends, respect those; otherwise, fall back to the
        // bookends passed by the parent schedule.
        let starts_at = self
            .get_series_options()
            .local_starts_at_datetime()
            .unwrap_or(starts_at);
        let ends_at = self
            .get_series_options()
            .local_ends_at_datetime()
            .unwrap_or(ends_at);

        let mut datetime_cursor =
            set_datetime_cursor_safely(starts_at, self.naive_starts_at_time());

        while datetime_cursor < ends_at {
            let occurrence_candidate_datetime_option =
                self.next_occurrence_candidate(&datetime_cursor);

            if let Some(occurrence_candidate_datetime) = occurrence_candidate_datetime_option {
                if occurrence_candidate_datetime >= starts_at
                    && occurrence_candidate_datetime <= ends_at
                {
                    occurrences.push(Occurrence {
                        starts_at_unix_timestamp: occurrence_candidate_datetime.timestamp(),
                        ends_at_unix_timestamp: (occurrence_candidate_datetime
                            + Duration::seconds(self.get_occurrence_duration_in_seconds()))
                        .timestamp(),
                        label: self.get_series_options().label(),
                    });
                }
            }

            datetime_cursor = self.advance_datetime_cursor(&datetime_cursor);
        }

        // Only collect every Nth occurrence if an interval has been requested.
        if self.get_series_options().interval > 1 {
            occurrences
                .into_iter()
                .step_by(self.get_series_options().interval as usize)
                .collect()
        } else {
            occurrences
        }
    }

    fn next_occurrence_candidate(&self, datetime_cursor: &DateTime<Tz>) -> Option<DateTime<Tz>>;
    fn advance_datetime_cursor(&self, datetime_cursor: &DateTime<Tz>) -> DateTime<Tz>;

    fn occurrence_candidate_matches_criteria(&self, _occurrence_candidate: &DateTime<Tz>) -> bool {
        return true;
    }
}
