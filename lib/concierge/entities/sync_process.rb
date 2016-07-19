# +SyncProcess+
#
# This entity corresponds to the occurrence of a synchronisation process
# happening for a host of a particular Roomorama supplier. It records
# metadata associated with the synchronisation process, allowing later
# analysis about how a given supplier behaves.
#
# A synchronisation process can be related to property metadata publishing
# to Roomorama as well as keeping the availabilities calendar up to date
# (see +BackgroundWorker+). The +stats+ field collects statistics specific
# for these kinds of events.
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
# +type+               - the type of synchronisation process that was executed.
# +stats+              - a JSON field containing statistics about the synchronisation
#                        process. Differs depending on the +type+ of sync process.
class SyncProcess
  include Hanami::Entity

  attributes :id, :host_id, :started_at, :finished_at, :successful, :type,
    :stats, :created_at, :updated_at
end
