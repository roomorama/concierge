module Concierge

  # +Concierge::S3+
  #
  # Convenience class to download files privately stored on Concierge's S3
  # bucket. Files that need to be downloaded in order for an integration to
  # be processed should be stored in that bucket (configured via +config/credentials+),
  # and downloaded using this file.
  #
  # Usage
  #
  #   credentials = Concierge::Credentials.for("aws")
  #   client      = Concierge::S3.new(credentials)
  #   client.read("woori/properties.json")
  class S3

    attr_reader :credentials

    # credentials - credentials for the +aws+ service.
    def initialize(credentials)
      @credentials = credentials
    end

    # returns a +String+ with the contents of the file specified in the
    # +location argument.
    #
    # The +location+ argument indicates the file *relative to the bucket
    # name* configured on the +credentials+ passed on initialization.
    def read(location)
      response = s3.get_object(bucket: credentials.s3_bucket, key: location)
      response.body.read
    end

    private

    def s3
      @s3 ||= Aws::S3::Client.new(
        region:            credentials.region,
        access_key_id:     credentials.access_key_id,
        secret_access_key: credentials.secret_access_key
      )
    end

  end

end
