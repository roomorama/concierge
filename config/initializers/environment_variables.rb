def verify_variables?
  # we cannot be sure that the VERIFY_VARIABLES var is set by adding it
  # to config/environment_variables.yml, so will use
  # exactly != "false" to verify if VERIFY_VARIABLES is not set
  ENV["VERIFY_VARIABLES"] != "false"
end

if verify_variables?
  Concierge::Environment.verify!
end
