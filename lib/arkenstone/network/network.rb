# frozen_string_literal: true

module Arkenstone
  module Network
    module ClassMethods
      def send_request(url, verb, data = nil, call_hooks = true)
        env = Arkenstone::Environment.new url:, verb:, body: data
        Arkenstone::Hook.call_request_hooks self, env if call_hooks
        response = Arkenstone::Network.send_request env
        handle_response response
        response
      end

      ### Takes appropriate action if the request was a success or failure.
      def handle_response(response)
        if Arkenstone::Network.response_is_success response
          Arkenstone::Hook.call_response_hooks self, response
        else
          Arkenstone::Hook.call_error_hooks self, response
        end
      end
    end

    class << self
      def included(base)
        base.extend Arkenstone::Network::ClassMethods
      end

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
        %w[200 204].include? response.code
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
        klass = Kernel.const_get('Net::HTTP').const_get(verb.capitalize)
        klass.new URI(url)
      end

      ### Fills in the body of a request with the appropriate serialized data.
      def set_request_data(request, data)
        data = data.to_json unless data.instance_of?(String)
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
