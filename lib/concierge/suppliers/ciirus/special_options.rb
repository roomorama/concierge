module Ciirus

  class SpecialOptions

    attr_reader :xml_msg, :json_msg

    # xml_msg should be +Nokogiri::XML::NodeSet+ instance or empty string
    def initialize(xml_msg: '', json_msg: '')
      @xml_msg = xml_msg
      @json_msg = json_msg
    end

    def to_xml(parent_builder)
      parent_builder.xmlMsg do
        parent_builder.parent << xml_msg
      end
      parent_builder.jSonMsg json_msg
    end
  end
end