# +Property+
#
# This entity corresponds to a property that was imported from a supplier and
# published on Roomorama.
#
# Attributes
#
# +id+         - the ID of the property on Concierge, an incremental integer.
# +identifier+ - an identifier of the property on the supplier system.
# +host_id+    - a foreign key to the +hosts+ table, indicating the account
#                that owns the property
# +data+       - a JSON field of the serialized information that describes all
#                data known about the property. Used to provide diffs when the
#                synchronisation process with suppliers kicks in. Includes
#                information on property images and units (for multi-unit properties)
class Property
  include Hanami::Entity

  attributes :id, :identifier, :host_id, :data, :created_at, :updated_at
end
