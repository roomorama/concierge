module Ciirus
  #  +Ciirus::BookingGuest+
  #
  # Auxiliary entity for Ciirus booking request generation
  BookingGuest = Struct.new(:name, :email, :address, :phone) do
    def to_xml(parent_builder)
      parent_builder.GuestName name
      parent_builder.GuestEmailAddress email
      parent_builder.GuestTelephone phone
      parent_builder.GuestAddress address
      parent_builder.GuestList {}
    end
  end
end