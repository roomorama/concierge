# +SyncProcess+
#
# This entity corresponds to the occurrence of a synchronisation process
# happening for a host of a particular Roomorama supplier. It records
# metadata associated with the synchronisation process, allowing later
# analysis about how a given supplier behaves.
#
# Attributes
#
# +id+                 - the ID of the the record on the database, automatically generated.
# +host_id+            - a foreign key to the +hosts+ table, indicating the account
#                        that was being synchronised in the process associated with the record.
# +started_at+         - a timestamp that indicates the time when the synchronisation process
#                        kicked in.
# +finished_at+        - a timestamp that indicates the time when the synchronisation process
#                        was completed.
# +properties_created+ - the number of properties published on Roomorama in a
#                        given synchronisation
# +properties_updated+ - the number of properties updated on Roomorama in a
#                        given synchronisation
# +properties_deleted+ - the number of properties deleted on Roomorama in a
#                        given synchronisation
class SyncProcess
  include Hanami::Entity

  attributes :id, :host_id, :started_at, :finished_at, :properties_created,
    :successful, :properties_updated, :properties_deleted, :created_at, :updated_at
end
