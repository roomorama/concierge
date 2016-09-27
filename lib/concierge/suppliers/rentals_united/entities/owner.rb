module RentalsUnited
  module Entities
    # +RentalsUnited::Entities::Owner+
    #
    # This entity represents an owner object.
    class Owner
      attr_accessor :id, :first_name, :last_name, :email, :phone

      def initialize(id:, first_name:, last_name:, email:, phone:)
        @id         = id
        @first_name = first_name
        @last_name  = last_name
        @email      = email
        @phone      = phone
      end
    end
  end
end
