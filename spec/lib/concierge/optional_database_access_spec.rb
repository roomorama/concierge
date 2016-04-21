require "spec_helper"

RSpec.describe Concierge::OptionalDatabaseAccess do
  class TestRepository
    attr_reader :fail, :operations

    def initialize
      @fail       = false
      @operations = []
    end

    def create(_)
      run(:create)
    end

    def update(_)
      run(:update)
    end

    def delete(_)
      run(:delete)
    end

    def failure_mode!
      @fail = true
    end

    def failure_mode?
      @fail
    end

    private

    def run(operation, &block)
      if failure_mode?
        raise Hanami::Model::UniqueConstraintViolationError
      else
        @operations << operation
        true
      end
    end
  end

  let(:repository) { TestRepository.new }
  subject { described_class.new(repository) }

  shared_examples "recovering from database errors" do |operation|
    let(:record) { double(to_h: { attribute: "value" }) }

    it "performs its #{operation} in case the repository succeeds without database errors" do
      subject.public_send(operation, record)
      expect(repository.operations).to eq [operation]
    end

    it "does not raise an error when performing #{operation} in case database access is compromised" do
      repository.failure_mode!

      subject.public_send(operation, record)
      expect(repository.operations).to be_empty
    end

    it "reports the incident in the emergency log" do
      repository.failure_mode!
      expect(Rollbar).to receive(:critical).with("Emergency Log: database_error")

      subject.public_send(operation, record)
    end
  end

  describe "#with_repository" do
    it "is successful in case the operation in the block succeeds" do
      subject.with_repository { |repo| repo.delete("key") }
      expect(repository.operations).to eq [:delete]
    end

    it "does not raise an error if database access is compromised" do
      repository.failure_mode!
      subject.with_repository { |repo| repo.delete("key") }

      expect(repository.operations).to be_empty
    end

    it "reports the incident to the emergency log in case of failure" do
      repository.failure_mode!
      expect(Rollbar).to receive(:critical).with("Emergency Log: database_error")

      subject.with_repository { |repo| repo.delete("key") }
    end
  end

  describe "#create" do
    it_behaves_like "recovering from database errors", :create
  end

  describe "#update" do
    it_behaves_like "recovering from database errors", :update
  end

  describe "#delete" do
    it_behaves_like "recovering from database errors", :delete
  end
end
