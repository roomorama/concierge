module Ciirus

  class SpecialOptions

    attr_reader :xml_msg, :json_msg

    def initialize(xml_msg: '', json_msg: '')
      @xml_msg = xml_msg
      @json_msg = json_msg
    end

    def to_xml(parent_builder)
      parent_builder.xmlMsg xml_msg
      parent_builder.jSonMsg json_msg
    end
  end
end