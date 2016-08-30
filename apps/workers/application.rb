module Workers
  class Application < Hanami::Application
    configure do
      root __dir__

      load_paths << [
        "comparison",
        "suppliers"
      ]

      cookies false
      layout false
    end

    configure :development do
      handle_exceptions false
      Woori::Importer.file_fetcher = File
    end

    configure :test do
      handle_exceptions false
      Woori::Importer.file_fetcher = File
    end

    configure :staging do
      handle_exceptions false
      Woori::Importer.file_fetcher = Concierge::S3.new(Concierge::Credentials.for("aws"))
    end

    configure :production do
      # this is a worker app, comprised of background processors. There is no need
      # handle exceptions, since we want them to be raised so that we
      # get notified.
      handle_exceptions false

      Woori::Importer.file_fetcher = Concierge::S3.new(Concierge::Credentials.for("aws"))
    end
  end
end

# as the +workers+ application is not mounted as a Rack app when the application
# boots, we need to manually require the files under +apps/workers+.
#
# This file will only be required if +CONCIERGE_APP+ is set to either +workers+
# or +all+ (development/test environments.)
Dir["./apps/workers/**/*.rb"].sort.each { |f| require f }
