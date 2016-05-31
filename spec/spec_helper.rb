ENV['HANAMI_ENV'] ||= 'test'

require_relative '../config/environment'
Hanami::Application.preload!

Dir[__dir__ + '/support/**/*.rb'].each { |f| require f }

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.disable_monkey_patching!

  config.order = :random
  Kernel.srand config.seed

  # make sure database is empty and in a clean state for tests
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.before(:each) do
    Concierge.context = Concierge::Context.new
  end
end
