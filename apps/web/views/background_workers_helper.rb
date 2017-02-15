# Helper functions for users of partials at templates/background_workers
#
module Web::Views::BackgroundWorkersHelper

  # Creates an HTML button/label for the status of a worker. +status+ is expected
  # to be a +String+ equal to one of +BackgroundWorker::STATUSES+.
  def status_label(status)
    css_class = {
      idle:    "secondary-button",
      queued:  "warning-button",
      running: "success-button"
    }.fetch(status.to_sym, "warning-button")

    html.button status, class: [css_class, " pure-button"].join
  end

  # Receives an instance of +BackgroundWorker+ and formats the
  # +next_run_at+ column for display.
  #
  # If that column is +null+, meaning the worker has just been created
  # and have never been run yet, the message indicates that the worker
  # will be kicked in soon (time varies depending of when the scheduler
  # will run next - see +Workers::Scheduler+).
  def format_time(worker)
    next_run_at = worker.next_run_at
    next_run_at ? time_formatter.present(next_run_at) : "Soon (in at most 10 minutes)"
  end

  def time_formatter
    @time_formatter ||= Web::Support::Formatters::Time.new
  end

  # uses the +pretty+ and +indent+ options provided by +Yajl::Encoder+ to
  # format the parsed JSON.
  def pretty_print_json(content)
    Yajl::Encoder.encode(content.to_h, pretty: true, indent: " " * 2)
  end

  def workers_for(host)
    BackgroundWorkerRepository.for_host(host)
  end
end
