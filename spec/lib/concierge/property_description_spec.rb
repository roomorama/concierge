require "spec_helper"

RSpec.describe Concierge::PropertyDescription do

  describe "#build" do
    context 'when property does not have required fields' do
      it "returns empty string if property does not have required fields" do
        p = Roomorama::Property.new('15')

        subject = described_class.new(p)
        expect(subject.build).to eq ''
      end

      it "returns empty string if property does not have required fields" do
        p = Roomorama::Property.load(
          {
            identifier: '15',
            disabled: true, # to make property valid
            type: 'apartment',
            max_guests: 4,
            number_of_bedrooms: 3,
            number_of_bathrooms: 2
          }
        ).value

        subject = described_class.new(p)
        expect(subject.build).to eq ''
      end
    end

    context 'when property does not have surface' do
      it "returns appropriate description" do
        p = Roomorama::Property.load(
          {
            identifier: '15',
            disabled: true, # to make property valid
            type: 'apartment',
            max_guests: 4,
            city: 'Omsk',
            number_of_bedrooms: 3,
            number_of_bathrooms: 2
          }
        ).value

        subject = described_class.new(p)
        expect(subject.build).to eq 'This is a charming apartment in Omsk, which can accommodate 4 guests.It has 3 bedrooms and 2 bathrooms.'
      end
    end

    context 'when property has all required fields' do
      it "returns appropriate description" do
        p = Roomorama::Property.load(
          {
            identifier: '15',
            disabled: true, # to make property valid
            type: 'apartment',
            max_guests: 4,
            city: 'Omsk',
            number_of_bedrooms: 3,
            number_of_bathrooms: 2,
            surface: 56
          }
        ).value

        subject = described_class.new(p)
        expect(subject.build).to eq 'This is a charming apartment in Omsk, which can accommodate 4 guests.The 56 square metres apartment has 3 bedrooms and 2 bathrooms.'
      end
    end
  end
end
