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
    refs.each { |ref| create_property(identifier: ref) }
  end

  describe "rake properties:patch_amenities" do
    let(:runner) { double("runner") }
    it "should dispatch diff api with only amenities" do
      expect(Workers::OperationRunner).to receive(:new).exactly(refs.count).times do
        runner
      end
      expect(runner).to receive(:perform).exactly(refs.count).times do
        Result.error(:test)
      end
      Rake::Task["properties:patch_amenities"].invoke(refs)
    end
  end
end
