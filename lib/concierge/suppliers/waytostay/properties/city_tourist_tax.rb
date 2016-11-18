class Waytostay::Properties::CityTouristTax

  attr_reader :tax

  # Only use the first item
  def initialize(taxes, currency)
    @tax = Hash[taxes.first.map{|(k,v)| [k.to_sym,v]}]

    @tax[:currency] = currency unless @tax.nil?
    check_max
  end

  def check_max
    if (@tax[:rate_type].include? "per_night") && @tax[:max_nights] == 0
      @tax[:rate_type] += "_no_max"
    end
  end

  def parse
    unless tax[:included]
      {
        en: Waytostay::Properties::Localiser.translate("en.city_tourist_tax.#{tax[:rate_type]}", tax),
        de: Waytostay::Properties::Localiser.translate("de.city_tourist_tax.#{tax[:rate_type]}", tax),
        es: Waytostay::Properties::Localiser.translate("es.city_tourist_tax.#{tax[:rate_type]}", tax),
        zh: Waytostay::Properties::Localiser.translate("zh.city_tourist_tax.#{tax[:rate_type]}", tax),
        zh_tw: Waytostay::Properties::Localiser.translate("zh_tw.city_tourist_tax.#{tax[:rate_type]}", tax),
      }
    else
      Hash.new("")
    end
  end
end
