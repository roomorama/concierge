module Workers

  # +Workers::Scheduler+
  #
  # This class is responsible for checking which hosts should be synchronised
  # (i.e., the +next_run_at+ column is either +nil+ or in a time in the past),
  # and enqueue the correspondent message to the queue to start the
  # synchronisation process.
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
    # enqueueing messages if necessary.
    def trigger_pending!
      HostRepository.pending_synchronisation.each do |host|
        log_event(host)
        update_timestamp(host)
        enqueue(host)
      end
    end

    private

    def default_logger
      Logger.new(LOG_PATH)
    end

    # updates the timestamp for next synchronisation to avoid enqueueing the same
    # hosts multiple times unnecessarily. If the synchronisation is performed
    # successfully by the worker, this timestamp is advanced again.
    def update_timestamp(host)
      three_hours_from_now = Time.now + 3 * 60 * 60
      host.next_run_at = three_hours_from_now

      HostRepository.update(host)
    end

    def enqueue(host)
      element = Workers::Queue::Element.new(
        operation: "sync",
        data:      { host_id: host.id }
      )

      queue.add(element)
    end

    def log_event(host)
      message = "action=%s host.username=%s host.identifier=%s" %
        ["sync", host.username, host.identifier]

      logger.info(message)
    end

    def queue
      @queue ||= begin
        credentials = Concierge::Credentials.for("sqs")
        Workers::Queue.new(credentials)
      end
    end

  end

end
