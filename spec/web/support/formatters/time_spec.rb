require "spec_helper"

RSpec.describe Web::Support::Formatters::Time do

  describe "#present" do
    it "formats the given timestamp in a human-readable format" do
      time = Time.new(2016, 7, 20, 11, 38, 43) # seconds ignored
      expect(subject.present(time)).to eq "July 20, 2016 at 11:38"
    end
  end

end
