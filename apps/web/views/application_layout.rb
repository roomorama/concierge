module Web
  module Views
    class ApplicationLayout
      include Web::Layout

      def flash_message(flash)
        type = flash_message_type(flash)
        return nil unless type

        flash[type]
      end

      def flash_message_type(flash)
        return :notice  if flash[:notice]
        return :error   if flash[:error]
      end
    end
  end
end
