module Ciirus
  # +Ciirus::XMLBuilder+
  #
  # This class is responsible for building request messages to the Ciirus's API
  # for different API calls.
  #
  # Usage
  #
  #   builder = Ciirus::XMLBuilder.new(credentials)
  #   message = builder.is_property_available(request_params)
  #   message # => xml string
  class XMLBuilder

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def is_property_available(property_id, check_in, check_out)
      message = builder.new do |xml|
        xml.root do
          xml.APIUsername credentials.username
          xml.APIPassword credentials.password
          xml.PropertyID property_id
          xml.ArrivalDate check_in
          xml.DepartureDate check_out
        end
      end
      message.doc.root.children.to_xml
    end

    def property_rates(property_id)
      message = builder.new do |xml|
        xml.root do
          xml.APIUserName credentials.username
          xml.APIPassword credentials.password
          xml.PropertyID property_id
        end
      end
      message.doc.root.children.to_xml
    end

    # Builds request message for properties Ciirus API method.
    # arrive_date and depart_date are dates in format 'dd MMM yyyy'
    def properties(management_company_id: 0, property_id: 0,
                   full_details: true, quote: false, sleeps: 0,
                   arrive_date: '', depart_date: '')
      message = builder.new(encoding: 'utf-8') do |xml|
        xml.root do
          xml.APIUsername credentials.username
          xml.APIPassword credentials.password
          xml.ArriveDate arrive_date
          xml.DepartDate depart_date
          xml.FilterOptions do
            xml.ManagementCompanyID management_company_id
            xml.CommunityID 0
            xml.PropertyID property_id
            xml.PropertyType 0
            xml.HasPool 2
            xml.HasSpa 2
            xml.PrivacyFence 2
            xml.CommunalGym 2
            xml.HasGamesRoom 2
            xml.IsGasFree false
            xml.Sleeps sleeps
            xml.PropertyClass 0
            xml.ConservationView 2
            xml.Bedrooms 0
            xml.WaterView 2
            xml.LakeView 2
            xml.WiFi 2
            xml.PetsAllowed 2
            xml.OnGolfCourse 2
            xml.SouthFacingPool 2
          end
          xml.SearchOptions do
            xml.ReturnTopX 0
            xml.ReturnFullDetails full_details
            xml.ReturnQuote quote
            xml.IncludePoolHeatInQuote false
          end
          xml.xmlMsg
          xml.jSonMsg
        end
      end
      message.doc.root.children.to_xml
    end

    # Builds request message for make booking Ciirus API method.
    # arrive_date and depart_date are dates in format 'dd MMM yyyy'
    def make_booking(property_id, arrival_date, departure_date, guest)
      message = builder.new(encoding: 'utf-8') do |xml|
        xml.root do
          xml.APIUsername credentials.username
          xml.APIPassword credentials.password
          xml.BD do
            xml.ArrivalDate arrival_date
            xml.DepartureDate departure_date
            xml.PropertyID property_id
            guest.to_xml(xml)
            xml.PoolHeatRequired false
            xml.xmlMsg
            xml.jSonMsg
          end
        end
      end
      message.doc.root.children.to_xml
    end

    def image_list(property_id)
      message = builder.new do |xml|
        xml.root do
          xml.APIUserName credentials.username
          xml.APIPassword credentials.password
          xml.PropertyID property_id
        end
      end
      message.doc.root.children.to_xml
    end

    def descriptions(property_id)
      message = builder.new do |xml|
        xml.root do
          xml.APIUserName credentials.username
          xml.APIPassword credentials.password
          xml.PropertyID property_id
        end
      end
      message.doc.root.children.to_xml
    end

    def reservations(property_id)
      message = builder.new do |xml|
        xml.root do
          xml.APIUsername credentials.username
          xml.APIPassword credentials.password
          xml.PropertyID property_id
          xml.xmlMsg
          xml.jSonMsg
        end
      end
      message.doc.root.children.to_xml
    end

    def property_permissions(property_id)
      message = builder.new do |xml|
        xml.root do
          xml.APIUsername credentials.username
          xml.APIPassword credentials.password
          xml.PropertyID property_id
        end
      end
      message.doc.root.children.to_xml
    end

    def extras(property_id)
      message = builder.new do |xml|
        xml.root do
          xml.APIUserName credentials.username
          xml.APIPassword credentials.password
          xml.PropertyID property_id
        end
      end
      message.doc.root.children.to_xml
    end

    def cancel(booking_id)
      message = builder.new do |xml|
        xml.root do
          xml.APIUsername credentials.username
          xml.APIPassword credentials.password
          xml.BookingID booking_id
        end
      end
      message.doc.root.children.to_xml
    end

    private

    def builder
      Nokogiri::XML::Builder
    end
  end
end
