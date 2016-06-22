module AtLeisure
  # +AtLeisure::LayoutItem+
  #
  # This class responsible for displaying references data
  class LayoutItem

    attr_reader :number, :name, :items

    def initialize(data)
      @number = data['Type']
      @name   = find_en_description(data)
      @items  = data['Items'].each_with_object({}) do |item, hash|
        hash[item['Number']] = find_en_description(item)
      end
    end

    private

    # retrieves english name of some reference parameter
    def find_en_description(item)
      item['Description'].find { |d| d['Language'] == 'EN' }['Description']
    end
  end
end
