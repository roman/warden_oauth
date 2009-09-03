module Warden
  module OAuth

    module Utils

      # Fetched from ActiveSupport to avoid dependencies
      def camelize(lower_case_and_underscored_word, first_letter_in_uppercase = true)
        if first_letter_in_uppercase
          lower_case_and_underscored_word.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_)(.)/) { $1.upcase }
        else
          lower_case_and_underscored_word.first.downcase + camelize(lower_case_and_underscored_word)[1..-1]
        end
      end

      def host_with_port(request)
        url = request.scheme + "://"
        url << request.host

        if request.scheme == "https" && request.port != 443 ||
            request.scheme == "http" && request.port != 80
          url << ":#{request.port}"
        end
        
        url
      end

      module_function :camelize, :host_with_port
      
    end

  end
end
