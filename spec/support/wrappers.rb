module Support
  # wraps Rack-style response
  ResponseWrapper = Struct.new(:status, :headers, :body)
end