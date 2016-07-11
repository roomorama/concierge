# +BackgroundWorker+
#
# This entity represents a type of background, synchronising worker associated
# with a given host. Hosts can have multiple workers related to synchronising
# property metadata as well as the calendar of availabilities. However, for some
# suppliers, calendar information is provided alongside property metadata, making
# it redundant to have separate workers for each. This class makes it easy to
# associate differents kinds of background workers as supplier integrations see fit.
#
# Attributes
#
# +id+          - the ID of the the record on the database, automatically generated.
# +supplier_id+ - a foreign key to the +suppliers+ table, indicating which supplier
#                 the background worker is associated with.
# +next_run_at+ - a timestamp that indicates when the background worker should be
#                 invoked next.
# +interval+    - how often (in seconds), the background worker should be invoked.
# +type+        - the type of synchronisation performed by the background worker.
# +status+      - the status of the worker, which indicate its activity at a given moment.
class BackgroundWorker
  include Hanami::Entity

  # possible values for the +type+ column of a background worker:
  #
  # +metadata+       - where processing of property metadata is fetched, parsed and
  #                    synchronised with Roomorama. Includes property images.
  # +availabilities+ - processing of the calendar of availabilities for a property.
  #                    Indicates availabilities and prices.
  TYPES    = %w(metadata availabilities)

  # possibile statuses a worker can be in:
  #
  # +idle+    - the background worker is not being run, and the +next_run_at+ column
  #             stores a timestamp in the future.
  # +running+ - the background worker is currently running and therefore should not
  #             be rescheduled.
  STATUSES = %w(idle running)

  attributes :id, :supplier_id, :next_run_at, :interval, :type, :status,
    :created_at, :updated_at
end
