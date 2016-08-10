module Concierge::Flows

  # +Concierge::Flows::RemoteHostCreation+
  #
  # This class encapsulates the creation of host on Roomorama, returning an access_token
  # It's currently called from the rake task hosts:create_from_yml
  #
  class RemoteHostCreation
    include Hanami::Validations
    include Concierge::JSON

    attribute :identifier,     presence: true # host's identifier on supplier's system
    attribute :username,       presence: true # username on roomorama
    attribute :fee_percentage, presence: true
    attribute :phone,          presence: true
    attribute :supplier,       presence: true
    attribute :access_token,   presence: true

    def perform
      if HostRepository.identified_by(identifier).any?
        return Result.error(:host_exists, "Found #{identifier} on concierge repository")
      end

      res = create_roomorama_host(identifier,
                                  username,
                                  supplier.name,
                                  phone,
                                  access_token)
      return res unless res.success?

      parsed_response = json_decode(res.value.body)
      return parsed_response unless parsed_response.success?
      Concierge::Flows::HostCreation.new(
        supplier:       supplier,
        identifier:     identifier,
        username:       username,
        access_token:   parsed_response.value["access_token"],
        fee_percentage: fee_percentage,
        config_path:    Hanami.root.join("config", "suppliers.yml").to_s
      ).perform
    end

    private

    def create_roomorama_host(identifier, username, supplier_name, phone, access_token)
      create_host = Roomorama::Client::Operations.create_host(name: identifier,
                                                              username: username,
                                                              email: "#{supplier_name}@roomorama.com",
                                                              phone: phone,
                                                              supplier_name: supplier_name)
      client = Roomorama::Client.new(access_token)
      client.perform(create_host)
    end
  end
end
