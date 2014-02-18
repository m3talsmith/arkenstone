module Arkenstone
  module Network

    class << self
      
      ### All http requests go through here. 
      def send_request(request_env)
        http = create_http request_env.url
        request = build_request request_env.url, request_env.verb
        set_request_data request, request_env.body
        set_request_headers request, request_env.headers unless request_env.headers.nil?
        http.request request
      end

      ### Determines if the response was successful.
      # TODO: Refactor this to handle more status codes.
      # TODO: How do we handle redirects (30x)? 
      def response_is_success(response)
        %w(200 204).include? response.code
      end

      ### Creates the http object used for requests.
      def create_http(url)
        uri = URI(url)
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http
      end

      ### Builds a Net::HTTP request object for the appropriate verb.
      def build_request(url, verb)
        klass = Kernel.const_get("Net::HTTP").const_get(verb.capitalize)
        klass.new URI(url)
      end

      ### Fills in the body of a request with the appropriate serialized data.
      def set_request_data(request, data)
        data = data.to_json unless data.class == String
        request.body = data
        request.content_type = 'application/json'
      end

      ### Sets HTTP headers on the request.
      def set_request_headers(request, headers)
        headers.each { |key, val| request.add_field key, val }
      end
    end
  end
end
