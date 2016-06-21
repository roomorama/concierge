module AtLeisure
  class AmenitiesMapper

    def map(meta_data)
      amenities     = []
      basic         = meta_data['LanguagePackENV4']
      layout_simple = basic['LayoutSimple']

      amenities_map.each do |key, value|
        amenities << key.to_s if Array(value).any? { |v| layout_simple.downcase.include?(v) }
      end

      costs_on_site = basic['CostsOnSite']

      bed_linen = costs_on_site.find { |cost| cost['Description'] == 'Bed linen' && cost['Value'] == 'Included' }
      towels    = costs_on_site.find { |cost| cost['Bath towels'] == 'Bed linen' && cost['Value'] == 'Included' }
      amenities << 'bed_linen_and_towels' if bed_linen && towels

      amenities
    end


    private

    def amenities_map
      {
        airconditioning:  'airconditioning',
        cabletv:          'cable',
        elevator:         'lift',
        gym:              'fitness',
        wheelchairaccess: 'single bed adapted for disabled',
        internet:         'internet',
        kitchen:          'kitchen',
        balcony:          'balcony',
        outdoor_space:    ['patio', 'garden'],
        parking:          'parking',
        pool:             ['swimmingpool', 'poolhouse'],
        tv:               'tv',
        laundry:          'dryer'
      }
    end
  end
end