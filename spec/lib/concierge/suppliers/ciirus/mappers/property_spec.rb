require 'spec_helper'

RSpec.describe Ciirus::Mappers::Property do

  context 'for valid result hash' do
    let(:result_hash) do
      Concierge::SafeAccessHash.new(
        {
          property_id: '33680',
          management_company_name: 'Floriwood Property Management',
          main_image_url: 'http//images.ciirus.com/properties/11015/33680/images/33656-Claus-Ebster-1008.jpg',
          mc_property_name: "Carol's Kingdom",
          website_property_name: "Carol's Kingdom",
          description_set_id: '854',
          community: 'Crescent Lakes',
          bedrooms: '3',
          sleeps: '6',
          bathrooms: '2',
          xco: '28.2252710',
          yco: '-81.5005140',
          bullet1: 'Luxury Villa',
          bullet2: 'Close to all the theme parks',
          bullet3: 'Private Pool',
          bullet4: 'Fully Air conditioned',
          bullet5: 'Fully equipped kitchen',
          currency_symbol: '$',
          currency_code: 'USD',
          has_pool: true,
          has_spa: true,
          games_room: true,
          property_type: 'Apartment',
          property_class: 'Deluxe',
          host_mc_user_id: '11006',
          quote_excluding_tax: '1179.00',
          quote_including_tax: '1308.69',
          less_than_minimum_nights_stay: false,
          minimum_nights_stay: '3',
          communal_pool: false,
          communal_gym: false,
          conservation_view: false,
          water_view: false,
          golf_view: false,
          golf_included: false,
          wi_fi: false,
          internet: false,
          wired_internet_access: false,
          pets_allowed: false,
          stroller: false,
          crib: false,
          high_chair: false,
          air_con: false,
          electric_fireplace: false,
          gas_fireplace: false,
          wood_burning_fireplace: false,
          free_calls: false,
          free_solar_heated_pool: false,
          packn_play: false,
          privacy_fence: false,
          south_facing_pool: false,
          bbq: false,
          air_hockey_table: false,
          big_screen_tv: false,
          cd_player: false,
          dvd_player: false,
          foosball_table: false,
          grill: false,
          hair_dryer: false,
          tv_in_every_bedroom: false,
          vcr: false,
          indoor_jacuzzi: false,
          indoor_hot_tub: false,
          outdoor_hot_tub: false,
          paved_parking: false,
          pool_access: false,
          rocking_chairs: false,
          video_games: false,
          fishing: false,
          extra_bed: false,
          sofa_bed: false,
          twin_single_beds: '0',
          full_beds: '0',
          queen_beds: '0',
          king_beds: '0',
          address1: '5452 Crepe Myrtle Circle',
          city: 'Kissimmee',
          country: 'USA',
          zip: '34758'
        }

      )
    end

    it 'returns Property entity' do
      property = subject.build(result_hash)

      expect(property).to be_a(Ciirus::Entities::Property)
    end

    it 'returns mapped property entity' do
      property = subject.build(result_hash)

      expect(property.property_id).to eq('33680')
      expect(property.property_name).to eq("Carol's Kingdom")
      expect(property.mc_property_name).to eq("Carol's Kingdom")
      expect(property.address).to eq('5452 Crepe Myrtle Circle')
      expect(property.zip).to eq('34758')
      expect(property.city).to eq('Kissimmee')
      expect(property.bedrooms).to eq(3)
      expect(property.sleeps).to eq(6)
      expect(property.type).to eq('Apartment')
      expect(property.country).to eq('USA')
      expect(property.xco).to eq(28.225271)
      expect(property.yco).to eq(-81.500514)
      expect(property.bathrooms).to eq(2)
      expect(property.king_beds).to eq(0)
      expect(property.queen_beds).to eq(0)
      expect(property.full_beds).to eq(0)
      expect(property.twin_beds).to eq(0)
      expect(property.extra_bed).to be false
      expect(property.sofa_bed).to be false
      expect(property.pets_allowed).to be false
      expect(property.currency_code).to eq('USD')
      expect(property.amenities).to eq(['pool'])
    end
  end
end
