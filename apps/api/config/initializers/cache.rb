# subscribes to +Concierge::Announcer+ events published by the
# +Concierge::Cache+ class. See that class documentation,
# as well that of the classes under +Concierge::Context+ to understand
# the rationale.

Concierge::Announcer.on(Concierge::Cache::CACHE_HIT) do |key, value, content_type|
  cache_hit = Concierge::Context::CacheHit.new(
    key:          key,
    value:        value,
    content_type: content_type
  )

  Concierge.context.augment(cache_hit)
end

Concierge::Announcer.on(Concierge::Cache::CACHE_MISS) do |key|
  cache_miss = Concierge::Context::CacheMiss.new(
    key: key
  )

  Concierge.context.augment(cache_miss)
end
