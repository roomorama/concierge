module Jtb
  module XmlBuilder
    VERSION    = '2013'
    LANGUAGE   = 'EN'
    NAMESPACES = {
        'xmlns:xsd'     => 'http://www.w3.org/2001/XMLSchema',
        'xmlns:xsi'     => 'http://www.w3.org/2001/XMLSchema-instance',
        'xmlns:jtb'     => 'http://service.api.genesis2.jtbgmt.com/',
        'xmlns:soapenv' => 'http://schemas.xmlsoap.org/soap/envelope/'
    }

    def build_availabilities(attributes)
      message = builder.new do |xml|
        xml.root(NAMESPACES) do
          credentials(xml)
          xml['jtb'].AvailRequestSegments {
            xml['jtb'].AvailRequestSegment {
              xml['jtb'].HotelSearchCriteria {
                xml['jtb'].Criterion(SortType: "PRICE", AvailStatus: "ALL") {
                  xml['jtb'].HotelCode(Code: attributes[:property_id])
                  xml['jtb'].RoomStayCandidates(SearchCondition: "OR") {
                    xml['jtb'].RoomStayCandidate(RoomTypeCode: attributes[:room_type_code], Quantity: "1")
                  }
                  xml['jtb'].StayDateRange(Start: attributes[:check_in], End: attributes[:check_out])
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

    def credentials(xml)
      xml['jtb'].POS {
        xml['jtb'].Source {
          xml['jtb'].RequestorID(ID: @id, UserName: @user, MessagePassword: @password) {
            xml['jtb'].CompanyName(Code: @company)
            xml['jtb'].BasicInfo(Version: VERSION, Language: LANGUAGE)
          }
        }
      }
    end
  end
end