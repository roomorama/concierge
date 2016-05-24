# +Supplier+
#
# Suppliers are the main reason for Concierge's existence. The +Supplier+ entity
# represents one of Roomorama's supply partners - companies that provide an API
# through which properties can be imported and published.
#
# Attributes:
#
# * +id+   - the ID of the supplier. A numeric, serial value.
# * +name+ - the supplier name.
class Supplier
  include Hanami::Entity

  attributes :id, :name
end
