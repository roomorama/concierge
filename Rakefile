require 'rake'
require 'hanami/rake_tasks'

# rake tasks that does not gets invoked directly - it is defined so that it can
# later be referenced as a dependency of rake tasks defined in files under
# +lib/tasks+. All it does is to preload the app so that all classes are
# available to the rake task.
task :environment do
  require_relative "config/environment"
  Hanami::Application.preload!
end

# simulate Rails' convention loading Rake files under +lib/tasks/*.rake+
Dir["./lib/tasks/*.rake"].sort.each { |file| load file }
