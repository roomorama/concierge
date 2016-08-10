module Concierge::Flows

  # +Concierge::Flows::RemoteHostCreation+
  #
  # This class encapsulates the creation of host on Roomorama, returning an access_token
  # It's currently called from the rake task hosts:create_from_yml
  #
  class RemoteHostCreation
    include Hanami::Validations

    attribute :host_identifier, presence: true
    attribute :fee_percentage,  presence: true
    attribute :phone,           presence: true
    attribute :supplier,        presence: true
    attribute :access_token,    presence: true

    def perform
      if HostRepository.identified_by(host_identifier).any?
        return Result.error(:host_exists, "Found #{host_identifier} on concierge repository")
      end

      res = create_roomorama_host(host_identifier,
                                  supplier.name,
                                  phone,
                                  access_token)
      return res unless res.success?

      response = JSON.parse(res.value.body)
      Concierge::Flows::HostCreation.new(
        supplier:       supplier,
        identifier:     host_identifier,
        username:       username(host_identifier),
        access_token:   response["access_token"],
        fee_percentage: fee_percentage,
        config_path:    Hanami.root.join("config", "suppliers.yml").to_s
      ).perform
    end

    private

    def create_roomorama_host(identifier, supplier_name, phone, access_token)
      create_host = Roomorama::Client::Operations.create_host(name: identifier,
                                                              username: username(identifier),
                                                              email: "#{supplier_name}@roomorama.com",
                                                              phone: phone,
                                                              supplier_name: supplier_name)
      client = Roomorama::Client.new(access_token)
      client.perform(create_host)
    end

    # Transform supplier's host identifier to Roomorama's
    # Currently returns the same thing
    def username(identifier)
      identifier
    end
  end
end
