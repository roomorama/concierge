# +Host+
#
# The +Host+ entity represents a host account on Roomorama. Typically, supplier
# partners are divided into different host accounts (Roomorama user accounts),
# each with its own set of properties. The +hosts+ table keeps track of
# integrated host accounts for each supplier.
#
# Attributes:
#
# * +supplier_id+  - a foreign key to the +suppliers+ table.
# * +identifier+   - the identifier for the account, on the supplier's system.
# * +username+     - the username of the user account on Roomorama. Present only
#                    for identification purposes.
# * +access_token+ - the API access token used to identify the host on Roomorama's API.
class Host
  include Hanami::Entity

  attributes :id, :supplier_id, :identifier, :username, :access_token, :created_at, :updated_at
end
