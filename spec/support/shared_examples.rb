# frozen_string_literal: true

# requires variables:
# - series_options_hash
# - occurrences
RSpec.shared_examples "a series that supports optional occurrence labels" do
  context "when a label is given" do
    before { series_options_hash.merge!(label: "My Nice Occurrence") }

    it "returns an array of occurrences tagged with the label" do
      expect(occurrences.all? { |o| o.label == "My Nice Occurrence" }).to eq(true)
    end
  end

  context "when no label is given" do
    it "returns an array of occurrences without a label" do
      expect(occurrences.all? { |o| o.label.nil? }).to eq(true)
    end
  end
end

# requires variables:
# - series_options_hash
# - occurrences
RSpec.shared_examples "a series that supports an optional time_of_day" do
  context "when a time_of_day is given" do
  end

  context "when no time_of_day is given" do
  end
end

# requires variables:
# - series_options_hash
# - occurrences
RSpec.shared_examples "a series that supports the duration_in_seconds argument" do
  before { series_options_hash.merge!(duration_in_seconds: 3.hours.seconds) }

  it "creates occurrences with the requested duration in seconds" do
    expect(
      occurrences.all? { |o| (o.ends_at - o.starts_at) == 3.hours.seconds }
    ).to eq(true)
  end
end
