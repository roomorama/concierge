# +ExternalError+
#
# This entity corresponds to an external error that happened to Concierge while performing
# its task. The definition of external error is everything that is outside of Concierge's
# control, such as:
#
# * problems on supplier's services
# * network failures
# * bugs on supplier responses
# * invalid JSONs being returned back
# * missing response fields in supplier response payloads
#
# In any of these cases, the error should be persisted as an external error
# so that it can be analysed by a human later. This is the puprose of this
# class.
#
# Attributes:
#
# +id+          - a numerical unique identifier (sequence).
# +operation+   - the operation being run.
# +supplier+    - the supplier with which the issue occurred.
# +code+        - an error code.
# +message+     - an error message. Oftentimes, this will include a response payload.
# +happened_at+ - a timestamp indicating when the error happened.
class ExternalError
  include Hanami::Entity

  OPERATIONS = %w(quote booking)

  attributes :id, :operation, :supplier, :code, :message, :happened_at
end
