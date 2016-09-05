class Workers::Processor

  # +Workers::Processor::Master+
  #
  # This class is responsible to coordinate a set of worker processes that process
  # messages from the SQS queue (+Workers::Queue+), and wait for more messages.
  # It is able to:
  #
  # * prefork a given number of worker processes, given on initialization
  # * monitor child processes and recreate them if they die.
  # * clean up worker processes if the master is killed
  # * wrap worker process so that running synchronisation processes will not be aborted.
  #
  # Check the documentation of the methods and the logic for an understanding
  # of how this tasks are accomplished.
  #
  # Usage
  #
  #   master = Workers::Processor::Master.new(prefork: 5)
  #   master.load! # => creates 5 children processes
  #
  # Worker processes can be identified by their name. The master process
  # will be named +Roomorama/Concierge Processor::Master+, whereas worker
  # processes will be named +Roomorama/Concierge Processor::Worker N+, where
  # +N+ is the worker number.
  class Master

    # the context on which the process is running. Duplicates the program
    # name and arguments so that it can re-exec itself when necessary.
    # Heavily inspired on Unicorn's implementation of the same feature.
    CONTEXT = {
      progname: $0.dup,
      argv:     ARGV.map(&:dup)
    }

    CONTEXT[:cwd] = begin
      env = File.stat(pwd = ENV['PWD'])
      dir = File.stat(Dir.pwd)
      env.ino == dir.ino && env.dev == dir.dev ? pwd : Dir.pwd
    rescue
      Dir.pwd
    end

    attr_reader :workers, :prefork

    # prefork - the number of worker processes to fork.
    #           processors are executed at the same time.
    def initialize(prefork:)
      @prefork  = prefork
      @workers  = {}
      @reapers  = 0
      @reexec   = false
    end

    # creates worker processes, sets them up and waits for signals/dead children
    # to recreate.
    def load!
      # 1. set up handlers for SIGINT, SIGTERM and SIGQUIT
      setup_signals

      # 2. updates its own identification as the Master process
      setup_name("Master")

      # 3. Creates workers, as declared on initialization
      prefork.times do |n|
        create_worker(n+1)
      end

      # 4. Master loop: waits for dead children, and recreates them, updating
      #    the +workers+ data structure which maps worker identifiers to
      #    process IDs.
      loop do
        pid = Process.wait
        create_worker(workers.delete(pid))
      end
    end

    private

    # handles SIGINT, SIGTERM and SIGQUIT to:
    #
    # 1. reap all workers
    # 2. finish gracefully
    #
    # This is performed by the master process. Children, worker processes
    # use +setup_worker_signals+.
    #
    # If the master process receives an +USR2+ signal, it re-execs itself
    # so as to get the latest changes (to be triggered by a deployment script.)
    def setup_signals
      %w(INT TERM QUIT).each do |signal|
        trap(signal) do
          @reapers += 1

          unless @reapers > 1
            reap_workers
            exit(0)
          end
        end
      end

      trap "USR2" do
        # avoid re-execing in case a previous signal was already sent.
        unless @reexecing
          @reexecing = true
          reap_workers
          reexec
        end
      end
    end

    # this is called by the master process to terminate all workers. It sends
    # +SIGTERM+ to each children, and then loops waiting for them to terminate
    # (if a worker is busy processing a message, it waits until that is finished
    # to terminate.)
    def reap_workers
      workers.each do |pid, _|
        terminate(pid)
      end

      begin
        # waits for every children to terminate
        loop { Process.wait }
      rescue Errno::ECHILD
        # if there are no more children, continue
      end

      # clean up the PID data structure for the worker processes
      workers.clear
    end

    def terminate(pid)
      Process.kill("TERM", pid)
    rescue Errno::ESRCH
      # in case the process does not exist (was manually killed), ignore the
      # error and keep terminating workers.
    end

    # creates a new worker process, identified by +n+, a number from
    # +0+ to +prefork - 1+. Forks a new worker processes, updates parents
    # data structures, and initiates the worker loop for the children classes.
    def create_worker(n)
      if pid = fork
        # parent process: updates the +workers+ data structure, with the
        # format
        #
        #   { PID => <id> }
        workers[pid] = n
      else
        # children process:

        # store the identifier so that the process name can be easily updated
        # if needed later
        @identifier = n

        # 1. sets up signal handlers for the worker processes
        setup_worker_signals

        # 2. sets up the process name to +Worker N+
        setup_name "Worker #{n}"

        # 3. configures the database connection on the children process.
        setup_database

        # 4. cleans up the +workers+ data structure, inherited from the
        #    parent, since a worker process does not manages other workers.
        workers.clear

        # 5. prepares the queue for polling for incoming messages
        prepare_queue

        # 6. initiates the worker loop
        worker_loop
      end
    end

    def prepare_queue
      poller.before do |*|
        throw :stop_polling if @killed
      end
    end

    # the main worker loop, executed by every worker process. It polls for messages
    # from +Workers::Queue+ indefinitely, using +Workers::Processor+ to process
    # each of them.
    #
    # For each incoming message, it sets this process as +busy+ so that if any
    # signals are received while a message is being processed, it will not be
    # suddenly aborted. When the operation is done and a signal has been received,
    # the process is terminated as soon as the message is finished processing.
    def worker_loop
      poller.poll do |message|
        busy do
          Workers::Processor.new(message.body).process!
        end
      end

      # this should be reached only through +stop_polling+ and +@killed+.
      exit!(0)
    rescue => err
      # if there is any error while processing a message on the queue, report
      # it to Rollbar and keep working on messages.
      Rollbar.error(err)
      retry
    end

    # makes sure that the process is labeled as +busy+ while the given block
    # is being run.
    def busy
      @busy = true
      yield
    ensure
      @busy = false
    end

    # re-execs itself, so as to load the newest version of the application.
    def reexec
      if fork
        exit(0)
      else
        # children: changes current directory to that of the original master
        # process, then re-execs itself.
        Dir.chdir(CONTEXT[:cwd])

        command = [CONTEXT[:progname]].concat(CONTEXT[:argv])
        exec(*command)
      end
    end

    # for worker process, if a deadly signal is received, we:
    #
    # - exit immediately if there is no message being processed;
    # - sets up the +killed+ flag so that when the current message is done processing,
    #   the process if finished.
    def setup_worker_signals
      %w(INT TERM QUIT).each do |signal|
        trap(signal) do
          # 1. updates the name so that an analysis tool can see that the signal
          #    was received and the process is aware of its termination
          setup_name "Worker #{@identifier} - terminating"

          # 2. if the process is not currently processing any request, finish
          #    immediately
          exit!(0) unless @busy

          # 3. if the process is currently processing a request, mark it as killed
          #    so that the process can terminate when the processing is done.
          @killed = true
        end
      end
    end

    # each new forked work needs to restablish its own database connection.
    # See https://devcenter.heroku.com/articles/forked-pg-connections#unicorn-server
    #
    # If this is not done, the connection cannot be shared and it causes database
    # connectivity issues.
    def setup_database
      Hanami::Model.load!
    end

    def queue
      @queue ||= begin
        credentials = Concierge::Credentials.for("aws")
        Workers::Queue.new(credentials)
      end
    end

    def poller
      @poller ||= queue.poller
    end

    def setup_name(label)
      $0 = [File.basename(CONTEXT[:progname]), label].concat(CONTEXT[:argv]).join(' ')
    end
  end
end
