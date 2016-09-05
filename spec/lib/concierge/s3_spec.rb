require "spec_helper"

RSpec.describe Concierge::S3 do
  let(:credentials) { Concierge::Credentials.for("aws") }

  subject { described_class.new(credentials) }

  describe "#read" do
    it "gets the requested object from S3" do
      s3       = subject.send(:s3)
      response = double(body: double(read: "content"))

      expect(s3).to receive(:get_object).with(bucket: "concierge-test-bucket", key: "supplier/file") { response }
      expect(subject.read("supplier/file")).to eq "content"
    end
  end
end
