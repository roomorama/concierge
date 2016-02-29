module Jtb
  class Api

    NAMESPACES = {
        'xmlns:xsd'     => 'http://www.w3.org/2001/XMLSchema',
        'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:jtb'     => 'http://service.api.genesis2.jtbgmt.com/',
        'xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/'
    }
    ENDPOINTS  = {
        GA_HotelAvail_v2013: {
            staging:     {
                wsdl:                 'https://trial-www.jtbgenesis.com/genesis2-demo/services/GA_HotelAvail_v2013?wsdl',
                env_namespace:        :soapenv,
                namespace_identifier: 'jtb',
                endpoint:             'http://trial-www.jtbgenesis.com/genesis2-trial/services/GA_HotelAvail_v2013'
            },
            development: {
                wsdl:                 'https://www.jtbgenesis.com/genesis2/services/GA_HotelAvail_v2013?wsdl',
                env_namespace:        :soapenv,
                namespace_identifier: 'jtb',
                endpoint:             'https://www.jtbgenesis.com/genesis2/services/GA_HotelAvail_v2013'
            },
            production:  {
                wsdl:                 'https://www.jtbgenesis.com/genesis2/services/GA_HotelAvail_v2013?wsdl',
                env_namespace:        :soapenv,
                namespace_identifier: 'jtb',
                endpoint:             'https://www.jtbgenesis.com/genesis2/services/GA_HotelAvail_v2013'
            }
        },
        GA_HotelRes_v2013:   {
            staging:     {
                wsdl:                 'https://trial-www.jtbgenesis.com/genesis2-demo/services/GA_HotelRes_v2013?wsdl',
                env_namespace:        :soapenv,
                namespace_identifier: 'jtb',
                endpoint:             'http://trial-www.jtbgenesis.com/genesis2-trial/services/GA_HotelRes_v2013'
            },
            development: {
                wsdl:                 'https://trial-www.jtbgenesis.com/genesis2-demo/services/GA_HotelRes_v2013?wsdl',
                env_namespace:        :soapenv,
                namespace_identifier: 'jtb',
                endpoint:             'http://trial-www.jtbgenesis.com/genesis2-trial/services/GA_HotelRes_v2013'
            },
            production:  {
                wsdl:                 'https://www.jtbgenesis.com/genesis2/services/GA_HotelRes_v2013?wsdl',
                env_namespace:        :soapenv,
                namespace_identifier: 'jtb',
                endpoint:             'https://www.jtbgenesis.com/genesis2/services/GA_HotelRes_v2013'
            }
        }
    }

    def initialize(credentials)
      credentials.each do |k, v|
        instance_variable_set(:"@#{k}", v)
      end
    end

    # options = {
    #    property_id:4329089,
    #    from_date:"2014-11-29",
    #    to_date:"2014-12-01",
    #    room_type_code:"JP1",
    #  }

    #  response: {
    #    availability_status: "OK",
    #    start_date: "2014-11-28",
    #    end_date: "2014-11-28",
    #    rate_plan: 'FHAHJ2301STD3JP4',
    #    rate: 600
    #  }

    def get_availabilites(options)
      begin

        room     = get_room(options[:property_id], options[:from_date], options[:to_date], options[:room_type_code])
        response = room[:ga_hotel_avail_rs][:room_stays][:room_stay].each.map do |room_stay|
          {
              rate:                room_stay[:room_rates][:room_rate][:total][:@amount_after_tax],
              start_date:          room_stay[:time_span][:@start],
              end_date:            room_stay[:time_span][:@end],
              rate_plan:           room_stay[:rate_plans][:rate_plan][:@rate_plan_id],
              availability_status: room_stay[:@availability_status]
          }
        end

      rescue Exception => e
        puts "error #{e}"
      end
    end

    # options = {
    #   property_id:4329089,
    #   from_date:"2014-11-29",
    #   to_date:"2014-12-01",
    #   room_type_code:"JP1",
    #   first_name:"James",
    #   last_name:"Watling",
    #   gender:"male",
    #   num_guests: 4,
    #   rate_plan:"FHAHJ2301STD3JP1"
    # }

    # response = {
    #   success: true,
    #   booking_id: 45345,
    #   total_after_tax: "45334.00"
    # }

    def create_booking(options)
      response = build_booking(options)
      if response[:ga_hotel_res_rs].keys.include? :errors
        return response[:ga_hotel_res_rs][:errors][:error_info][:@short_text]
      end
      booking = response[:ga_hotel_res_rs][:hotel_reservations][:hotel_reservation]
      {
          success:         booking[:@res_status],
          booking_id:      booking[:unique_id][:@id],
          total_after_tax: booking[:res_global_info][:total][:@amount_after_tax]
      }
    end

    private

    def build_booking(options)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.root(NAMESPACES) do
          build_credentials(xml)
          xml['jtb'].HotelReservations {
            xml['jtb'].HotelReservation(PassiveIndicator: false) {
              xml['jtb'].ResGlobalInfo {
                xml['jtb'].RatePlans {
                  xml['jtb'].RatePlan(RatePlanID: options[:rate_plan])
                }
                xml['jtb'].TimeSpan(EndDate: options[:to_date], StartDate: options[:from_date])
              }
              xml['jtb'].ResGuests {
                (1..options[:num_guests].to_i).each do |guest|
                  xml['jtb'].ResGuest(AgeQualifyingCode: "ADL", PrimaryIndicator: (guest == 1), ResGuestRPH: guest) {
                    xml['jtb'].Profiles {
                      xml['jtb'].ProfileInfo {
                        xml['jtb'].Profile {
                          xml['jtb'].Customer {
                            xml['jtb'].PersonName {
                              xml['jtb'].GivenName options[:first_name]+ "#{guest}"
                              xml['jtb'].NamePrefix get_salutation(options[:gender])
                              xml['jtb'].Surname options[:last_name]
                            }
                          }
                        }
                      }
                    }
                  }
                end
              }
              xml['jtb'].RoomStays {
                xml['jtb'].RoomStay {
                  xml['jtb'].ResGuestRPHs {
                    (1..options[:num_guests].to_i).each do |guest|
                      xml['jtb'].ResGuestRPH(RPH: guest)
                    end
                  }
                  xml['jtb'].RoomTypes {
                    xml['jtb'].RoomType(RoomTypeCode: options[:room_type_code])
                  }
                }
              }
            }
          }
        end
      end
      make_request(:gby011, builder.doc.root.children, :GA_HotelRes_v2013)
    end

    def get_room(room_id, from_date, to_date, room_type_code)
      builder = Nokogiri::XML::Builder.new do |xml|
        xml.root(NAMESPACES) do
          build_credentials(xml)
          xml['jtb'].AvailRequestSegments {
            xml['jtb'].AvailRequestSegment {
              xml['jtb'].HotelSearchCriteria {
                xml['jtb'].Criterion(SortType: "PRICE", AvailStatus: "ALL") {
                  xml['jtb'].HotelCode(Code: room_id)
                  xml['jtb'].RoomStayCandidates(SearchCondition: "OR") {
                    xml['jtb'].RoomStayCandidate(RoomTypeCode: room_type_code, Quantity: "1")
                  }
                  xml['jtb'].StayDateRange(Start: from_date, End: to_date)
                }
              }
            }
          }
        end
      end
      make_request(:gby010, builder.doc.root.children, :GA_HotelAvail_v2013)
    end

    def make_request(method_name, message, endpoint)
      Savon.client(ENDPOINTS[endpoint][@environment.to_sym]).call(method_name, message: message).body
    end

    def build_credentials(xml)
      xml['jtb'].POS {
        xml['jtb'].Source {
          xml['jtb'].RequestorID(ID: @user_id, UserName: @user_name, MessagePassword: @password) {
            xml['jtb'].CompanyName(Code: @company_name)
            xml['jtb'].BasicInfo(Version: @api_version, Language: @api_language)
          }
        }
      }
    end

    def get_salutation(gender)
      case gender
        when "male", "Male"
          "Mr"
        when "female", "Female"
          "Ms"
        else
          "-"
      end
    end

  end
end