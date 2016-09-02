module Avantio
  module Mappers
    class Description

      def build(description_raw)
        accommodation_code = fetch_accommodation_code(description_raw)
        user_code = fetch_user_code(description_raw)
        login_ga = fetch_login_ga(description_raw)
        images = fetch_images(description_raw)
        description = fetch_description(description_raw)

        Avantio::Entities::Description.new(
          accommodation_code, user_code, login_ga, images, description
        )
      end

      private

      def fetch_accommodation_code(description_raw)
        description_raw.at_xpath('Accommodation/AccommodationCode')&.text.to_s
      end

      def fetch_user_code(description_raw)
        description_raw.at_xpath('Accommodation/UserCode')&.text.to_s
      end

      def fetch_login_ga(description_raw)
        description_raw.at_xpath('Accommodation/LoginGA')&.text.to_s
      end

      def fetch_images(description_raw)
        urls_raw = description_raw.xpath('Images/Image/OriginalImageURL')
        urls_raw.map(&:text)
      end

      def fetch_description(description_raw)
        description_raw.at_xpath('InternationalizedItem[Language/text() = "en"]/Description')&.text.to_s
      end
    end
  end
end
