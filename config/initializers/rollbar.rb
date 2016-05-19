Rollbar.configure do |config|
  config.access_token = ENV["ROLLBAR_ACCESS_TOKEN"]
  config.environment  = Hanami.env
  config.framework    = "Hanami #{Hanami::VERSION}"
  config.root         = Hanami.root.to_s
  config.enabled      = %w(staging production).include?(Hanami.env)
  config.code_version = Concierge::VERSION
end
