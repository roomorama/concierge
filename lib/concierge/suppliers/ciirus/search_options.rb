module Ciirus

  class SearchOptions

    attr_reader :top_x, :full_details, :quote, :pool_heat

    def initialize(top_x: 0, full_details: true, quote: false, pool_heat: false)
      @top_x = top_x
      @full_details = full_details
      @quote = quote
      @pool_heat = pool_heat
    end

    def to_xml(parent_builder)
      parent_builder.SearchOptions do
        parent_builder.ReturnTopX top_x
        parent_builder.ReturnFullDetails full_details
        parent_builder.ReturnQuote quote
        parent_builder.IncludePoolHeatInQuote pool_heat
      end
    end

  end
end