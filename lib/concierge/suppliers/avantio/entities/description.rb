module Avantio
  module Entities
    class Description
      attr_reader :accommodation_code, :user_code, :login_ga,
                  :property_id, :images, :description

      def initialize(accommodation_code, user_code, login_ga, images, description)
        @accommodation_code = accommodation_code
        @user_code          = user_code
        @login_ga           = login_ga
        @images             = images
        @description        = description
      end

      # Roomorama property id for given accommodation
      def property_id
        @property_id ||= Avantio::PropertyId.from_avantio_ids(
          accommodation_code, user_code, login_ga
        ).property_id
      end
    end
  end
end