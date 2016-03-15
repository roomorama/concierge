module JTB
  # +JTB::XMLBuilder+
  #
  # This class is responsible for building request messages t the response sent by JTB's API
  # for different API calls.
  #
  # Usage
  #
  #   builder = JTB::XMLBuilder.new(credentials)
  #   builder.quote_price(request_params)
  #   # => <jtb:POS>...</jtb:POS>
  #        <jtb:AvailRequestSegments>...</jtb:AvailRequestSegments>

  class XMLBuilder
    VERSION    = '2013'
    LANGUAGE   = 'EN'
    NAMESPACES = {
      'xmlns:xsd'     => 'http://www.w3.org/2001/XMLSchema',
      'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
      'xmlns:jtb'     => 'http://service.api.genesis2.jtbgmt.com/',
      'xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/'
    }

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # builds message for +JTB::API+ +quote_price+ method
    def quote_price(params)
      message = builder.new do |xml|
        xml.root(NAMESPACES) do
          build_credentials(xml)
          xml['jtb'].AvailRequestSegments {
            xml['jtb'].AvailRequestSegment {
              xml['jtb'].HotelSearchCriteria {
                xml['jtb'].Criterion(SortType: "PRICE", AvailStatus: "ALL") {
                  xml['jtb'].HotelCode(Code: params[:property_id])
                  xml['jtb'].RoomStayCandidates(SearchCondition: "OR") {
                    xml['jtb'].RoomStayCandidate(RoomTypeCode: params[:unit_id], Quantity: "1")
                  }
                  xml['jtb'].StayDateRange(Start: params[:check_in], End: params[:check_out])
                }
              }
            }
          }
        end
      end
      message.doc.root.children
    end

    # builds message for +JTB::API+ +create_booking+ method
    # full description on 28th page of JTB "API References Guide"
    # message has a test behaviour if +PassiveIndicator+ is true JTB will not create a booking
    # but return success response without reservation code
    def build_booking(params, rate)
      message = builder.new do |xml|
        xml.root(NAMESPACES) do
          build_credentials(xml)
          xml['jtb'].HotelReservations {
            xml['jtb'].HotelReservation(PassiveIndicator: params.fetch(:simulate, false)) {
              xml['jtb'].ResGlobalInfo {
                xml['jtb'].RatePlans {
                  xml['jtb'].RatePlan(RatePlanID: rate.rate_plan)
                }
                xml['jtb'].TimeSpan(StartDate: params[:check_in], EndDate: params[:check_out])
              }
              xml['jtb'].ResGuests { guests_info(xml, params) }
              xml['jtb'].RoomStays {
                xml['jtb'].RoomStay {
                  xml['jtb'].ResGuestRPHs {
                    1.upto(params[:guests]) do |guest|
                      xml['jtb'].ResGuestRPH(RPH: guest)
                    end
                  }
                  xml['jtb'].RoomTypes {
                    xml['jtb'].RoomType(RoomTypeCode: params[:unit_id])
                  }
                }
              }
            }
          }
        end
      end
      message.doc.root.children
    end

    private

    def builder
      Nokogiri::XML::Builder
    end

    def build_credentials(xml)
      xml['jtb'].POS {
        xml['jtb'].Source {
          xml['jtb'].RequestorID(ID: credentials.id, UserName: credentials.user, MessagePassword: credentials.password) {
            xml['jtb'].CompanyName(Code: credentials.company)
            xml['jtb'].BasicInfo(Version: VERSION, Language: LANGUAGE)
          }
        }
      }
    end

    def guests_info(xml, params)
      customer = params[:customer]
      1.upto(params[:guests]) do |guest|
        xml['jtb'].ResGuest(AgeQualifyingCode: "ADL", PrimaryIndicator: (guest == 1), ResGuestRPH: guest) {
          xml['jtb'].Profiles {
            xml['jtb'].ProfileInfo {
              xml['jtb'].Profile {
                xml['jtb'].Customer {
                  xml['jtb'].PersonName {
                    xml['jtb'].GivenName customer[:first_name]+ "#{guest}"
                    xml['jtb'].NamePrefix name_prefix(customer[:gender].to_s)
                    xml['jtb'].Surname customer[:last_name]
                  }
                }
              }
            }
          }
        }
      end
    end

    def name_prefix(gender)
      case gender.downcase
      when "male"
        "Mr"
      when "female"
        "Ms"
      else
        "-"
      end
    end

  end
end