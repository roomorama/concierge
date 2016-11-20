enforce_on_envs = ["staging", "production"]

if enforce_on_envs.include?(Hanami.env)
  Concierge::Suppliers.validate_suppliers!
end
