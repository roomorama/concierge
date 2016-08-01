module Ciirus

  class FilterOptions

    attr_reader :management_company_id, :property_id, :community_id,
                :property_type, :filters

    def initialize(management_company_id: 0, property_id: 0, property_type: 0)
    @management_company_id = management_company_id
      @property_id = property_id
      @property_type = property_type
      @community_id = 0 # always no matter what community

      @filters = FilterOption.new
      yield(@filters) if block_given?
    end

    def to_xml(parent_builder)
      parent_builder.FilterOptions do
        parent_builder.ManagementCompanyID management_company_id
        parent_builder.CommunityID community_id
        parent_builder.PropertyID property_id
        parent_builder.PropertyType property_type
        filters.to_xml(parent_builder)
      end
    end


    class FilterOption

      Filter = Struct.new(:filter_name, :default_value)

      OPTIONS = {
        has_pool:          Filter.new('HasPool', 2),
        has_spa:           Filter.new('HasSpa', 2),
        private_fance:     Filter.new('PrivacyFence', 2),
        communal_gym:      Filter.new('CommunalGym', 2),
        has_games_room:    Filter.new('HasGamesRoom', 2),
        is_gas_free:       Filter.new('IsGasFree', false),
        sleeps:            Filter.new('Sleeps', 0),
        property_class:    Filter.new('PropertyClass', 0),
        conservation_view: Filter.new('ConservationView', 2),
        bedrooms:          Filter.new('Bedrooms', 0),
        water_view:        Filter.new('WaterView', 2),
        lake_view:         Filter.new('LakeView', 2),
        wifi:              Filter.new('WiFi', 2),
        pets_allowed:      Filter.new('PetsAllowed', 2),
        on_golf_course:    Filter.new('OnGolfCourse', 2),
        south_facing_pool: Filter.new('SouthFacingPool', 2)
      }

      OPTIONS.keys.each do |key|
        attr_writer key
        define_method(key) { filter_value(key) }
      end

      def to_xml(parent_builder)
        OPTIONS.each do |key, opt|
          parent_builder.send(opt.filter_name, filter_value(key))
        end
      end

      private

      def filter_value(method)
        value = self.instance_variable_get("@#{method}")
        value || OPTIONS[method].default_value
      end
    end
  end
end