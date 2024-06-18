

RSpec.describe Coruscate do
  it "has a version number" do
    expect(Coruscate::VERSION).not_to be nil
  end

  xit "does something useful" do
    expect(false).to eq(true)
  end

  xit "uses a custom rust blank method" do
    expect("my string".rust_blank?).to eq(false)
  end

  it "does a thing" do
    expect(Coruscate.return_hello).to eq("Hello!")
  end

  it "can do a thing with time" do
    original_time = Time.now

    pp original_time.inspect

    time = Coruscate.return_modified_time(original_time)
    pp time.inspect
    pp time[0].inspect
    pp time[0].class
  end

  fit "can do a thing with a class" do

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
end
