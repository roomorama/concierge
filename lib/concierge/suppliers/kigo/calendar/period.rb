module Kigo::Calendar

  TimeInterval = Struct.new(:interval) do
    # returns days count computed by NIGHT, MONTH, YEAR unit
    # for some reasons period number might be zero
    def days
      return if interval['NUMBER'].zero?
      multiplier = { 'MONTH' => 30, 'YEAR' => 365 }.fetch(interval['UNIT'], 1)
      interval['NUMBER'] * multiplier
    end
  end

end