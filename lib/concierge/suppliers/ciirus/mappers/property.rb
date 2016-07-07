module Ciirus
  module Mappers
    class Property
      class << self
        # Maps hash representation of Ciirus API GetProperties response
        # to +Ciirus::Entities::Property+
        def build(hash)
          attrs = {}
          copy_property_id!(hash, attrs)
          copy_property_name!(hash, attrs)
          copy_address!(hash, attrs)
          copy_zip!(hash, attrs)
          copy_city!(hash, attrs)
          copy_bedrooms!(hash, attrs)
          copy_sleeps!(hash, attrs)
          copy_min_nights_stay!(hash, attrs)
          copy_type!(hash, attrs)
          copy_country!(hash, attrs)
          copy_xco!(hash, attrs)
          copy_yco!(hash, attrs)
          copy_bathrooms!(hash, attrs)
          copy_king_beds!(hash, attrs)
          copy_queen_beds!(hash, attrs)
          copy_full_beds!(hash, attrs)
          copy_twin_beds!(hash, attrs)
          copy_extra_bed!(hash, attrs)
          copy_sofa_bed!(hash, attrs)
          copy_pets_allowed!(hash, attrs)
          copy_currency_code!(hash, attrs)
          copy_amenities!(hash, attrs)

          Entities::Property.new(attrs)
        end

        private

        def copy_property_id!(hash, attrs)
          attrs[:property_id] = hash[:property_id]
        end

        def copy_property_name!(hash, attrs)
          attrs[:property_name] = hash[:website_property_name]
        end

        def copy_address!(hash, attrs)
          attrs[:address] = hash[:address1]
        end

        def copy_zip!(hash, attrs)
          attrs[:zip] = hash[:zip]
        end

        def copy_city!(hash, attrs)
          attrs[:city] = hash[:city]
        end

        def copy_bedrooms!(hash, attrs)
          attrs[:bedrooms] = hash[:bedrooms].to_i
        end

        def copy_sleeps!(hash, attrs)
          attrs[:sleeps] = hash[:sleeps].to_i
        end

        def copy_min_nights_stay!(hash, attrs)
          attrs[:min_nights_stay] = hash[:minimum_nights_stay].to_i
        end

        def copy_type!(hash, attrs)
          attrs[:type] = hash[:property_type]
        end

        def copy_country!(hash, attrs)
          attrs[:country] = hash[:country]
        end

        def copy_xco!(hash, attrs)
          attrs[:xco] = hash[:xco]
        end

        def copy_yco!(hash, attrs)
          attrs[:yco] = hash[:yco]
        end

        def copy_bathrooms!(hash, attrs)
          attrs[:bathrooms] = Float(hash[:bathrooms])
        end

        def copy_king_beds!(hash, attrs)
          attrs[:king_beds] = hash[:king_beds].to_i
        end

        def copy_queen_beds!(hash, attrs)
          attrs[:queen_beds] = hash[:queen_beds].to_i
        end

        def copy_full_beds!(hash, attrs)
          attrs[:full_beds] = hash[:full_beds].to_i
        end

        def copy_twin_beds!(hash, attrs)
          attrs[:twin_beds] = hash[:twin_single_beds].to_i
        end

        def copy_extra_bed!(hash, attrs)
          attrs[:extra_bed] = hash[:extra_bed]
        end

        def copy_sofa_bed!(hash, attrs)
          attrs[:sofa_bed] = hash[:sofa_bed]
        end

        def copy_pets_allowed!(hash, attrs)
          attrs[:pets_allowed] = hash[:pets_allowed]
        end

        def copy_currency_code!(hash, attrs)
          attrs[:currency_code] = hash[:currency_code]
        end

        def copy_amenities!(hash, attrs)
          amenities = []
          amenities << 'wifi' if hash[:wi_fi]
          amenities << 'internet' if has_internet?(hash)
          amenities << 'tv' if has_tv?(hash)
          amenities << 'parking' if hash[:paved_parking]
          amenities << 'airconditioning' if hash[:air_con]
          amenities << 'pool' if has_pool?(hash)
          amenities << 'gym' if hash[:communal_gym]
          amenities << 'outdoor_space' if has_outdoor_space?(hash)

          attrs[:amenities] = amenities
        end

        def has_tv?(hash)
          hash[:big_screen_tv] ||
          hash[:dvd_player] ||
          hash[:tv_in_every_bedroom] ||
          hash[:vcr]
        end

        def has_internet?(hash)
          hash[:internet] ||
          hash[:wired_internet_access]
        end

        def has_pool?(hash)
          hash[:has_pool] ||
          hash[:communal_pool] ||
          hash[:free_solar_heated_pool] ||
          hash[:south_facing_pool] ||
          hash[:pool_access]
        end

        def has_outdoor_space?(hash)
          hash[:bbq] ||
          hash[:grill] ||
          hash[:outdoor_hot_tub]
        end
      end
    end
  end
end
