require 'spec_helper'

RSpec.describe "hosts rake tasks" do
  include Support::Factories
  let!(:old_stdout) { $stdout.dup }

  before do
    Rake.application = Rake::Application.new
    load Hanami.root.join('Rakefile')
    Rake::Task.define_task(:environment)

    # redirect standard output to +/dev/null+ so that feedback produced by the
    # Rake task does not get mingled with RSpec's output. The +after+ block is
    # responsible for setting +stdout+ back to its original value.
    $stdout.reopen("/dev/null")
  end

  after do
    $stdout.reopen(old_stdout)
  end

  describe "rake hosts:create_from_yml" do
    let(:path) { Hanami.root.join("spec", "fixtures", "hosts.csv").to_s }
    let(:supplier) { create_supplier }
    let(:access_token) { "test_token" }
    let(:usernames) { ["abc", "def"] }
    let(:ids) { ["123", "234"] }
    let(:remote_host_creation) { double("RemoteHostCreation") }
    it "should call remote host creation for each row" do
      expect(Concierge::Flows::RemoteHostCreation).to receive(:new).twice do |**args|
        expect(usernames.include?(args[:username])).to be true
        expect(ids.include?(args[:identifier])).to be true
        expect(args[:supplier]).to be_a Supplier
        remote_host_creation
      end
      expect(remote_host_creation).to receive(:perform).twice do
        Result.new("success")
      end
      Rake::Task["hosts:create_from_csv"].invoke(path, supplier.name, access_token)
    end
  end
end
