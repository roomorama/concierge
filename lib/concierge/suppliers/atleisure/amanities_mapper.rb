module AtLeisure
  # +AtLeisure::AmenitiesMapper+
  #
  # Represents AtLeisure property payload to Roomorama format
  class AmenitiesMapper

    def map(meta_data)
      amenities     = []
      basic         = meta_data['LanguagePackENV4']
      layout_simple = basic['LayoutSimple'].downcase

      amenities_map.each do |key, value|
        amenities << value if layout_simple.include?(key)
      end

      costs_on_site = basic['CostsOnSite']

      bed_linen = costs_on_site.find { |cost| cost['Description'] == 'Bed linen' && cost['Value'] == 'Included' }
      towels    = costs_on_site.find { |cost| cost['Bath towels'] == 'Bed linen' && cost['Value'] == 'Included' }
      amenities << 'bed_linen_and_towels' if bed_linen && towels

      amenities.compact.uniq
    end


    private

    def amenities_map
      {
        'airconditioning'                 => 'airconditioning',
        'cable'                           => 'cabletv',
        'lift'                            => 'elevator',
        'fitness'                         => 'gym',
        'single bed adapted for disabled' => 'wheelchairaccess',
        'internet'                        => 'internet',
        'kitchen'                         => 'kitchen',
        'balcony'                         => 'balcony',
        'garden'                          => 'outdoor_space',
        'patio'                           => 'outdoor_space',
        'parking'                         => 'parking',
        'poolhouse'                       => 'pool',
        'swimming pool'                   => 'pool',
        'tv'                              => 'tv',
        'dryer'                           => 'laundry'
      }
    end
  end
end