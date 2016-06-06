namespace :background do
  desc "Checks for hosts pending synchronisation and enqueues them"
  task scheduler: :environment do
    unless %i(all workers).include?(Concierge.app)
      raise "This Rake task is only available on the workers app"
    end

    scheduler = Workers::Scheduler.new
    scheduler.trigger_pending!
  end
end
