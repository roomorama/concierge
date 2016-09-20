require "spec_helper"

RSpec.describe Workers::Processor::Pdf do

  subject { described_class.new }

  describe "#render_pdf" do
    it "returns pdf file" do
      pdf = subject.send(:render_pdf,
               {template_path: Hanami.root.join("spec/fixtures/pdf_template.html.erb"),
               locals: {test_local_var: "onetwo"}})
      expect(pdf).to be_a String
    end
  end
end
