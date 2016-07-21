module API::Views

  class Cancel
    include API::View

    def render
      response = {
        status:     "ok",
        cancelled_reference_number: cancelled_reference_number
      }

      json(response)
    end

  end

end
