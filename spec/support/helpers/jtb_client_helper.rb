require 'savon/mock/spec_helper'

module JtbClientHelper
  include Savon::SpecHelper

  def stub_quote_price_response
    savon.expects(:gby010).with(message: {}).returns(File.read('spec/support/fixtures/jtb/GA_HotelAvailRS.xml'))
  end

  def attribute_for(message, tag, attribute)
    message.xpath("//jtb:#{tag}").map { |item| item[attribute] }.first
  end

  def build_quote_response(availabilities)
    {
        ga_hotel_avail_rs: {
            room_stays: {
                room_stay: availabilities
            }
        }
    }
  end

  def availability(attributes)
    {
        rate_plans:           { rate_plan: { :@rate_plan_id => attributes[:rate_plan_id] } },
        time_span:            { :@start => attributes[:date], :@end => attributes[:date] },
        room_rates:           { :room_rate => { total: { :@amount_after_tax => attributes[:price] } } },
        :@availability_status => attributes[:status]
    }
  end

end