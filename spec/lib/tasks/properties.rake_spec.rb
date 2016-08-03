require 'spec_helper'

RSpec.describe "properties rake tasks" do
  include Support::Factories

  before do
    @rake = Rake::Application.new
    Rake.application = @rake
    load Hanami.root.join('Rakefile')
    Rake::Task.define_task(:environment)
  end

  let(:refs) { ["001", "002"] }

  before do
    refs.each do |ref|
      create_property(identifier: ref,
        data: {amenities: "wifi,laundry",
          images: [
            { identifier: "PROP1IMAGE", url: "https://www.example.org/image.png" }
          ]})
    end
  end

  describe "rake properties:patch_amenities" do
    let(:runner) { double("runner") }
    it "should dispatch diff api with only amenities" do
      expect(Workers::OperationRunner).to receive(:new).exactly(refs.count).times do
        runner
      end
      expect(runner).to receive(:perform).exactly(refs.count).times do |operation, new_property|
        expect(new_property).to be_a Roomorama::Property
        diff = operation.property_diff
        expect(diff.to_h[:amenities]).to eq "wifi,laundry"
        Result.error(:test)
      end
      Rake::Task["properties:patch_amenities"].invoke(refs)
    end
  end
end
