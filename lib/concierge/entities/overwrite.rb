# +Overwrite+
#
# The +Overwrite+ entity holds the custom mapping that an admin
# want to impose on properties after pulling from Supplier's api.
#
# It can be "applied" on to a Roomorama::Property to overwrite specified
# fields. For example, an overwrite on the cancellation_policy:
#
#   Overwrite.new(
#     data: {"cancellation_policy": "flexible"},
#     property_identifier: "abc",
#     host_id: 1,
#   )
#
class Overwrite
  include Hanami::Entity

  attributes :id, :host_id, :property_identifier,
    :data, :created_at, :updated_at

  def validate
    return Result.error(:invalid_data, "Must be valid cancellation policy") unless valid_cancellation_policy?
    Result.new(true)
  end

  def valid_cancellation_policy?
    data["cancellation_policy"].nil? || Roomorama::CancellationPolicy.all.include?(data["cancellation_policy"])
  end

end
