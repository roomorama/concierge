# +PropertyRepository+
#
# Persistence and query methods for the +properties+ table.
#
# The list of properties on Concierge should reflect those that are published
# on Roomorama. If a supplier disconnects or removes certain properties, these
# should no longer be stored in this table.
class PropertyRepository
  include Hanami::Repository
end
