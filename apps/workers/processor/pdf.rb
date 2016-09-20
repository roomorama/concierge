class Workers::Processor

  # +Workers::Processor::Pdf+
  #
  # This class does the following:
  # - Renders a pdf for specified supplier, for example the
  #   guest checkin voucher for atleisure,
  # - Uploads the pdf to S3
  #
  class Pdf
    # data - the map of attributes passed as argument to the pdf queue element.
    #        Contains fields: +supplier_name+, +reference_number+
    def initialization(data)
      @data = data
    end

    # Renders a supplier view into pdf, and upload to s3
    def run
      template_locals = send("#{@data.get('supplier')}_template_locals", @data)
      pdf = render_pdf(template_path: @data.get('template_path'),
                       locals:        template_locals)
      upload_s3(pdf)
      Result.new({})
    end

    private

    def AtLeisure_template_locals(data)
      result = AtLeisure::Booking.fetch(data.get("reference_number"))
      return result unless result.success?

      booking_details = result.value
      {
        reference_number:     data.get("reference_number"),
        reservation_guests:   booking_details["NumberOfAdults"],
        arrival_time_from:    booking_details["ArrivalTimeFrom"],
        arrival_time_until:   booking_details["ArrivalTimeUnitl"],
        departure_time_from:  booking_details["DepartureTimeFrom"],
        departuer_time_until: booking_details["DepartureTimeUnitl"],
        booking_date:         booking_details["BookingDate"],
        guest_name:           booking_details["CustomerSurname"],
      }
    end

    def render_pdf(locals:nil, template_path:)
      b = OpenStruct.new(locals).instance_eval { binding }
      html_string = ERB.new(File.new(template_path).read).result(b)
      kit         = PDFKit.new(html_string)
      kit.to_pdf
    end

    def upload_s3(data)
      s3_cred = Concierge::Credentials.for("s3")

      s3 = Aws::S3::Client.new(
        region:      s3_cred.region_name,
        credentials: Aws::Credentials.new(s3_cred.access_key_id, s3_cred.secret_access_key)
      )

      s3.put_object({
        acl:         "public-read",
        body:        data,
        bucket_name: s3_cred.bucket_name
      })
    end
  end
end

