module RentalsUnited
  module Mappers
    # +RentalsUnited::Mappers::Owner+
    #
    # This class is responsible for building an owner object.
    class Owner
      attr_reader :owner_hash

      # Initialize +RentalsUnited::Mappers::Owner+ mapper
      #
      # Arguments:
      #
      #   * +owner_hash+ [Concierge::SafeAccessHash] owner hash
      def initialize(owner_hash)
        @owner_hash = owner_hash
      end

      def build_owner
        Entities::Owner.new(
          id:         owner_hash.get("@OwnerID"),
          first_name: owner_hash.get("FirstName"),
          last_name:  owner_hash.get("SurName"),
          email:      owner_hash.get("Email"),
          phone:      owner_hash.get("Phone")
        )
      end
    end
  end
end
