module JTB
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
  end
end