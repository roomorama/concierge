require "spec_helper"
require "timecop"

RSpec.describe SAW::Mappers::AvailabilityCalendar do
  before { Timecop.freeze(Time.local(2015,1,10)) }
  after { Timecop.return }

  it "returns roomorama property entity" do
    availability_calendar = described_class.build
    
    expect(availability_calendar).to be_kind_of(Hash)
    expect(availability_calendar.size).to eq(90)

    start_date = Time.now.to_date
    end_date = (Time.now + 89 * 24 * 60 * 60).to_date

    (start_date..end_date).each do |date|
      expect(availability_calendar[date.to_s]).to be true
    end
  end
end
