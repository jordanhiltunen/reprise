require "spec_helper"

RSpec.describe Coruscate do
  it "has a version number" do
    expect(Coruscate::VERSION).not_to be nil
  end

  it "can do a thing with a class" do

    my_schedule = Coruscate::Schedule.new(
      start_time: Time.current - 1.day,
      end_time: Time.current + 1.year,
      time_zone: "Hawaii"
    )

#     my_schedule.set_exclusions([[Time.current.to_i, Time.current.to_i], [Time.current.to_i, Time.current.to_i]])

    my_schedule.add_exclusion((Time.current - 5.minutes).to_i, (Time.current + 5.minutes).to_i)
#     my_schedule.add_exclusion((Time.current + 1.month - 5.hours).to_i, (Time.current + 1.month + 5.hours).to_i)

    pp my_schedule.inspect
    pp my_schedule.occurrences.size
    pp my_schedule.occurrences.inspect

    my_schedule.occurrences.each do |occurrence|

      pp "OCCURRENCE"
      pp occurrence
      # t = Time.at(occurrence).in_time_zone("Europe/Paris")
      pp occurrence.strftime("%a %b %e %Y %I:%M%p %z")
    end
  end

  describe "#repeats_weekly" do
    let(:schedule) do
      Coruscate::Schedule.new(
        start_time: Time.current - 1.day,
        end_time: Time.current + 2.months,
        time_zone: "Hawaii"
      )
    end

    before { travel_to Time.new(2024, 6, 30, 0, 0, 0) }

    it "generates an array of weekly occurrences" do
      schedule.repeat_weekly("tuesday", { hour: 1, minute: 2, second: 3 }, 300)

      expect(schedule.occurrences.size).to eq(9)
      expect(
        schedule.occurrences.map { |o| o.start_time.in_time_zone("Hawaii").strftime("%a %b %e %Y %I:%M%p %z") }
      ).to contain_exactly(
         "Tue Jul  2 2024 01:02AM -1000",
         "Tue Jul  9 2024 01:02AM -1000",
         "Tue Jul 16 2024 01:02AM -1000",
         "Tue Jul 23 2024 01:02AM -1000",
         "Tue Jul 30 2024 01:02AM -1000",
         "Tue Aug  6 2024 01:02AM -1000",
         "Tue Aug 13 2024 01:02AM -1000",
         "Tue Aug 20 2024 01:02AM -1000",
         "Tue Aug 27 2024 01:02AM -1000"
       )
    end
  end
end
