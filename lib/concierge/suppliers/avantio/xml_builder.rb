module Avantio
  # +Avantio::XMLBuilder+
  #
  # This class is responsible for building request messages to the Avantio's API
  # for different API calls.
  #
  # Usage
  #
  #   builder = Avantio::XMLBuilder.new(credentials)
  #   message = builder.booking_price(property_id)
  #   message # => xml string
  class XMLBuilder

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    def booking_price(property_id, guests, arrival_date, departure_date)
      message = builder.new do |xml|
        xml.root do
          credentials_xml(xml)
          xml.Criteria do
            accommodation_xml(xml, property_id)
            xml.Occupants do
              xml.AdultsNumber guests
            end
            xml.ArrivalDate arrival_date
            xml.DepartureDate departure_date
          end
        end
      end
      message.doc.root.children.to_xml
    end

    def is_available(property_id, guests, arrival_date, departure_date)
      message = builder.new do |xml|
        xml.root do
          credentials_xml(xml)
          xml.Criteria do
            accommodation_xml(xml, property_id)
            xml.Occupants do
              xml.AdultsNumber guests
            end
            xml.DateFrom arrival_date
            xml.DateTo departure_date
          end
        end
      end
      message.doc.root.children.to_xml
    end

    def set_booking(property_id, guests, arrival_date, departure_date, customer, test)
      # UNPAID: prebooking without confirmation
      # PETICION_INFORMACION: It does not neither do a booking nor block the period requested.
      #                       It just ask the accommodation owner for information about how the booking would be.
      booking_type = test ? 'PETICION_INFORMACION' : 'UNPAID'

      message = builder.new do |xml|
        xml.root do
          credentials_xml(xml)
          xml.BookingData do
            xml.ArrivalDate arrival_date
            xml.DepartureDate departure_date
            accommodation_xml(xml, property_id)
            xml.Occupants do
              xml.AdultsNumber guests
            end
            xml.ClientData do
              xml.Name customer[:first_name]
              xml.Surname customer[:last_name]
              xml.DNI
              xml.Address customer[:address]
              xml.Locality
              xml.PostCode
              xml.City
              xml.Country
              xml.Telephone customer[:phone]
              xml.Telephone2
              xml.EMail customer[:email]
              xml.Fax
              xml.Language 'EN'
            end
            xml.Board 'ROOM_ONLY'
            xml.PaymentMethod '26' # TODO: what does it mean?
            xml.BookingType booking_type
            xml.Comments
            xml.SendMailToOrganization true
            xml.SendMailToTourist false
          end
        end
      end
      message.doc.root.children.to_xml
    end

    def cancel(booking_code)
      message = builder.new do |xml|
        xml.root do
          credentials_xml(xml)
          xml.Localizer do
            xml.BookingCode booking_code
          end
          xml.Comments
          xml.SendMailToOrganization true
          xml.SendMailToTourist false
        end
      end
      message.doc.root.children.to_xml
    end

    private

    def credentials_xml(xml)
      xml.Credentials do
        xml.Language 'EN'
        xml.UserName credentials.username
        xml.Password credentials.password
      end
    end

    def accommodation_xml(xml, property_id)
      xml.Accommodation do
        xml.AccommodationCode property_id.accommodation_code
        xml.UserCode property_id.user_code
        xml.LoginGA property_id.login_ga
      end
    end

    def builder
      Nokogiri::XML::Builder
    end
  end
end
