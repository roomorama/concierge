module Workers

  # +Workers::Scheduler+
  #
  # This class is responsible for checking which hosts should be synchronised
  # (i.e., the +next_run_at+ column is either +nil+ or in a time in the past),
  # and asynchronously trigger their import process to kick-in.
  #
  # The import process is assumed to be listening to the +sync.<supplier-name>+
  # event via +Concierge::Announcer+. The subscribed handler for that event
  # receives one parameter, the +Host+ instance to be synchronised.
  #
  # This scheduler logs its work using a +logger+ instance given on initialization.
  # By default, its output is placed on +log/scheduler.log+. Activity on which
  # hosts were synchronised can be checked from there.
  class Scheduler

    # the default path to the file where the logs of this class are written.
    LOG_PATH = Hanami.root.join("log", "scheduler.log").to_s

    attr_reader :logger

    # logger - if given, it should be +Logger+ instance.
    def initialize(logger: default_logger)
      @logger = logger
    end

    # queries the +hosts+ table to identify which host should be synchronised,
    # triggering, asynchronously, the related event.
    def trigger_pending!
      HostRepository.pending_synchronisation.each do |host|
        supplier  = SupplierRepository.find(host.supplier_id)
        broadcast = ["sync", ".", supplier.name].join

        log_event(host)
        Concierge::Announcer.trigger_async(broadcast, host)
      end
    end

    private

    def default_logger
      Logger.new(LOG_PATH)
    end

    def log_event(host)
      message = "action=%s host.username=%s host.identifier=%s" %
        ["sync", host.username, host.identifier]

      logger.info(message)
    end

  end

end
