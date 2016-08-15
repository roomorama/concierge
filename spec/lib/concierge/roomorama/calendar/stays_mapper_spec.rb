require "spec_helper"

RSpec.describe Roomorama::Calendar::StaysMapper do
  describe "#map" do
    let(:stays) {
      [ Roomorama::Calendar::Stay.new({
          checkin:    "2016-01-01",
          checkout:   "2016-01-08",
          price: 700, # 100 per night
          available:  true
        }),
        Roomorama::Calendar::Stay.new({
          checkin:    "2016-01-01",
          checkout:   "2016-01-15",
          price: 700, # 50 per night
          available:  true
        }),
        Roomorama::Calendar::Stay.new({
          checkin:    "2016-02-02",
          checkout:   "2016-02-09",
          price: 70, # 10 per night
          available:  true
        })
      ]
    }

    subject { described_class.new(stays).map }

    it "should return expected availabilities" do
      expect(subject.count).to eq 40 # 01 Jan to 09 Feb
      av = lambda { |date| subject.find { |e| e.date == Date.parse(date) }.to_h }
      expect(av.call "2016-01-01").to eq({
        date:               Date.parse("2016-01-01"),
        available:          true,
        checkin_allowed:    true,
        checkout_allowed:   false,
        nightly_rate:       50, # Takes to minimum rate of the 2 stays
        valid_stay_lengths: [7, 14]
      })
      expect(av.call "2016-01-03").to eq({
        date:               Date.parse("2016-01-03"),
        available:          true,
        checkin_allowed:    false,
        nightly_rate:       50,
        checkout_allowed:   false
      })
      expect(av.call "2016-01-28").to eq({
        date:               Date.parse("2016-01-28"),
        available:          false,
        checkin_allowed:    false,
        checkout_allowed:   false
      })
      expect(av.call "2016-02-08").to eq({
        date:               Date.parse("2016-02-08"),
        available:          true,
        checkin_allowed:    false,
        nightly_rate:       10,
        checkout_allowed:   false
      })
      expect(av.call "2016-02-09").to eq({
        date:               Date.parse("2016-02-09"),
        available:          true,
        checkin_allowed:    false,
        nightly_rate:       10,
        checkout_allowed:   true
      })
    end
  end
end

