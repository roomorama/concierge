require 'spec_helper'

RSpec.describe Ciirus::Commands::PropertyPermissionsFetcher do
  include Support::Fixtures
  include Support::SOAPStubbing

  let(:credentials) do
    double(username: 'Foo',
           password: '123',
           url:      'http://example.org')
  end

  let(:property_id) { {property_id: '33680'} }

  let(:success_response) { read_fixture('ciirus/responses/property_permissions_response.xml') }
  let(:deleted_property_response) { read_fixture('ciirus/responses/deleted_property_permissions_response.xml') }
  let(:mc_disabled_property_response) { read_fixture('ciirus/responses/mc_disabled_property_permissions_response.xml') }
  let(:mc_disabled_clone_property_response) { read_fixture('ciirus/responses/mc_disabled_clone_property_permissions_response.xml') }
  let(:error_response) { read_fixture('ciirus/responses/error_property_permissions_response.xml') }
  let(:wsdl) { read_fixture('ciirus/wsdl.xml') }

  subject { described_class.new(credentials) }

  describe '#call' do
    context 'when remote call internal error happened' do
      it 'returns result with error' do
        allow_any_instance_of(Savon::Client).to receive(:call) { raise Savon::Error }
        result = subject.call(property_id)

        expect(result).not_to be_success
        expect(result.error.code).to eq :savon_error
      end
    end

    context 'when xml response is correct' do
      it 'returns success property permissions' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)

        expect(result).to be_a Result
        expect(result).to be_success
        expect(result.value).to be_a Ciirus::Entities::PropertyPermissions
      end

      it 'fills property permissions with right attributes' do
        stub_call(method: described_class::OPERATION_NAME, response: success_response)

        result = subject.call(property_id)

        permissions = result.value
        expect(permissions.property_id).to eq('33680')
        expect(permissions.mc_enable_property).to be_truthy
        expect(permissions.agent_enable_property).to be_truthy
        expect(permissions.agent_user_id).to eq('38716')
        expect(permissions.mc_user_id).to eq('11006')
        expect(permissions.native_property).to be_falsey
        expect(permissions.calendar_sync_property).to be_falsey
        expect(permissions.aoa_property).to be_falsey
        expect(permissions.time_share).to be_falsey
        expect(permissions.online_booking_allowed).to be_truthy
        expect(permissions.deleted).to be_falsey
      end

      it 'fills deleted property permissions with right deleted attribute' do
        stub_call(method: described_class::OPERATION_NAME, response: deleted_property_response)

        result = subject.call(property_id)

        expect(result).to be_success
        permissions = result.value
        expect(permissions.deleted).to be_truthy
      end

      it 'ignores mc disabled error message and returns permissions' do
        stub_call(method: described_class::OPERATION_NAME, response: mc_disabled_property_response)

        result = subject.call(property_id)

        expect(result).to be_success
        permissions = result.value
        expect(permissions.mc_enable_property).to be_falsey
      end

      it 'ignores mc disabled clone error message and returns permissions' do
        stub_call(method: described_class::OPERATION_NAME, response: mc_disabled_clone_property_response)

        result = subject.call(property_id)

        expect(result).to be_success
        permissions = result.value
        expect(permissions.mc_enable_property).to be_falsey
      end
    end

    context 'when xml contains error message' do
      it 'returns a result with error' do
        stub_call(method: described_class::OPERATION_NAME, response: error_response)

        result = subject.call(property_id)

        expect(result.success?).to be false
        expect(result.error.code).to eq(:not_empty_error_msg)
        expect(result.error.data).to eq(
          "The response contains not empty ErrorMsg: `Error (1001) This property has been orphaned, and does not have an MC.\n          Error (1010) No agent relation is configured between the supplier and the agent. Please contact Ciirus.\n        `"
        )
      end
    end
  end
end
