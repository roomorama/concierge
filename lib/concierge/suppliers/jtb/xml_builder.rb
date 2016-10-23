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
    DEFAULT_FIRST_NAME = 'Roomorama'
    DEFAULT_LAST_NAME = 'Guest'

    attr_reader :credentials

    def initialize(credentials)
      @credentials = credentials
    end

    # builds message for +JTB::API+ +quote_price+ method
    def quote_price(property_id, room_type_code, check_in, check_out)
      message = builder.new do |xml|
        xml.root(NAMESPACES) do
          build_credentials(xml)
          xml['jtb'].AvailRequestSegments {
            xml['jtb'].AvailRequestSegment {
              xml['jtb'].HotelSearchCriteria {
                xml['jtb'].Criterion(SortType: "PRICE", AvailStatus: "ALL") {
                  xml['jtb'].HotelCode(Code: property_id)
                  xml['jtb'].RoomStayCandidates(SearchCondition: "OR") {
                    xml['jtb'].RoomStayCandidate(RoomTypeCode: room_type_code, Quantity: "1")
                  }
                  xml['jtb'].StayDateRange(Start: check_in, End: check_out)
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
    # but return success response 'XXXXXXXXXX' reservation.reference_number
    def build_booking(params, rate, room_type_code)
      params = Concierge::SafeAccessHash.new(params)
      message = builder.new(encoding: 'utf-8') do |xml|
        xml.root(NAMESPACES) do
          build_credentials(xml)
          xml['jtb'].HotelReservations {
            xml['jtb'].HotelReservation(PassiveIndicator: credentials['test']) {
              xml['jtb'].ResGlobalInfo {
                xml['jtb'].RatePlans {
                  xml['jtb'].RatePlan(RatePlanID: rate.rate_plan)
                }
                xml['jtb'].TimeSpan(StartDate: params[:check_in], EndDate: params[:check_out])
              }
              xml['jtb'].ResGuests { guests_info(xml, params[:customer], rate.occupancy) }
              xml['jtb'].RoomStays {
                xml['jtb'].RoomStay {
                  xml['jtb'].ResGuestRPHs {
                    1.upto(rate.occupancy) do |guest|
                      xml['jtb'].ResGuestRPH(RPH: guest)
                    end
                  }
                  xml['jtb'].RoomTypes {
                    xml['jtb'].RoomType(RoomTypeCode: room_type_code)
                  }
                }
              }
            }
          }
        end
      end
      message.doc.root.children
    end

    def cancel(reservation)
      reference_number = ReferenceNumber.from_roomorama_reference_number(reservation.reference_number)
      message = builder.new(encoding: 'utf-8') do |xml|
        xml.root(NAMESPACES) do
          build_credentials(xml)
          xml['jtb'].UniqueID(ID: reference_number.reservation_id)
          xml['jtb'].Verification {
            xml['jtb'].RatePlans {
              xml['jtb'].RatePlan(RatePlanID: reference_number.rate_plan_id)
            }
            xml['jtb'].ReservationTimeSpan(Start: reservation.check_in)
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
          xml['jtb'].RequestorID(ID: credentials['id'], UserName: credentials['user'], MessagePassword: credentials['password']) {
            xml['jtb'].CompanyName(Code: credentials['company'])
            xml['jtb'].BasicInfo(Version: VERSION, Language: LANGUAGE)
          }
        }
      }
    end

    def guests_info(xml, customer, occupancy)
      1.upto(occupancy) do |guest|
        xml['jtb'].ResGuest(AgeQualifyingCode: "ADL", PrimaryIndicator: (guest == 1), ResGuestRPH: guest) {
          xml['jtb'].Profiles {
            xml['jtb'].ProfileInfo {
              xml['jtb'].Profile {
                xml['jtb'].Customer {
                  xml['jtb'].PersonName {
                    xml['jtb'].GivenName latin_only(customer[:first_name], default: DEFAULT_FIRST_NAME)
                    xml['jtb'].NamePrefix name_prefix(customer[:gender].to_s)
                    xml['jtb'].Surname latin_only(customer[:last_name], default: DEFAULT_LAST_NAME)
                  }
                }
              }
            }
          }
        }
      end
    end

    def latin_only(string, default:)
      # converts accented latin letters to ascii encoding
      normalized(string) || default
    end

    def normalized(string)
      string = string.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/,'').to_s
      string if !string.blank? && string.ascii_only?
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