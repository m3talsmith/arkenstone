require 'json'

module Arkenstone
  # # Document
  #
  # A `Document` is the main entry point for Arkenstone. A `Document` is a model that is retrieved and/or stored on a RESTful service. For example, if you have a web service that has a URL structure like:
  #
  #     http://example.com/users
  #
  # You can create a `User` model, include `Document` and it will automatically create methods to fetch and save data from that URL.
  #
  #     class User
  #       include Arkenstone::Document
  #
  #       url 'http://example.com/users'
  #
  #       attributes :first_name, :last_name, :email
  #     end
  #
  # Attributes create properties on instances that match up with the data returned by the `url`. Properties on the web service are ignored if they are not present within the `attributes` list.
  module Document
    class << self
      def included(base)
        base.send :include, Arkenstone::Document::InstanceMethods
        base.extend Arkenstone::Document::ClassMethods
        base.send :include, Arkenstone::Helpers::GeneralMethods
        base.extend Arkenstone::Helpers::GeneralMethods
        base.send :include, Arkenstone::Associations::InstanceMethods
        base.extend Arkenstone::Associations::ClassMethods
      end
    end

    module InstanceMethods
      ### The convention is for all Documents to have an id. 
      attr_accessor :id, :arkenstone_json, :arkenstone_attributes

      ### Easy access to all of the attributes defined for this Document.
      def attributes
        new_hash = {}
        self.class.arkenstone_attributes.each do |key|
          new_hash[key.to_sym] = self.send("#{key}")
        end
        self.arkenstone_json = new_hash.to_json
        new_hash
      end

      ### Set attributes for a Document. If a key in the `options` hash is not present in the attributes list, it is ignored.
      def attributes=(options)
        options.each do |key, value|
          self.send("#{key}=".to_sym, value) if self.respond_to? key
        end
        self.arkenstone_json = attributes.to_json
        self.attributes
      end

      ### Serializes the attributes to json.
      def to_json
        self.attributes.to_json
      end

      ### If this is a new Document, create it with a POST request, otherwise update it with a PUT.
      def save
        self.timestamp if self.respond_to?(:timestampable)
        response             = self.id ? put_document_data : post_document_data
        self.arkenstone_json = response.body
        self.attributes      = JSON.parse(response.body)
        return self
      end

      alias_method :save!, :save

      ### Update a single attribute. Performs validation (by calling `update_attributes`).
      def update_attribute(key, value)
        hash = { key.to_sym => value }
        self.update_attributes hash
      end

      ### Update multiple attributes at once. Performs validation (if that is setup for this document).
      def update_attributes(new_attributes)
        original_attrs = self.attributes.clone
        self.attributes = self.attributes.merge! new_attributes
        if has_validation_method?
          save_if_valid original_attrs
        else
          self.save
        end
      end

      # If a model passes validation, it is saved, otherwise the original attributes (`original_attrs`) are reset.
      # Assumes there is a validation method defined for the Document.
      def save_if_valid(original_attrs)
        if self.valid?
          self.save
        else
          self.attributes = original_attrs
          false
        end
      end

      ### Checks if there is a `valid?` method.
      def has_validation_method?
        self.class.method_defined? :valid?
      end

      # Retrieves a RESTful URL for an instance, in this case by tacking an id onto the end of the `arkenstone_url`.
      # Example:
      #
      #     # arkenstone_url
      #     http://example.com/users
      #
      #     # instance_url
      #     http://example.com/users/100
      def instance_url
        "#{full_url(self.class.arkenstone_url)}#{id}"
      end

      ### The full RESTful URL for a Document.
      def class_url
        full_url(self.class.arkenstone_url)
      end

      ### Save via POST.
      def post_document_data
        http_response class_url, :post
      end

      ### Save via PUT.
      def put_document_data
        http_response instance_url, :put
      end

      ### Sends a DELETE request to the `instance_url`.
      def destroy
        resp = http_response instance_url, :delete
        self.class.response_is_success resp
      end

      ### Sends a network request with the `attributes` as the body.
      def http_response(url, method=:post)
        self.class.send_request url, method, saveable_attributes
      end

      def saveable_attributes
        return self.attributes if self.class.arkenstone_hooks.nil?
        attrs = {}
        self.class.arkenstone_hooks.each do |hook|
          new_attrs = hook.encode_attributes(self.attributes)
          attrs.merge! new_attrs unless new_attrs.nil?
        end
        attrs.empty? ? self.attributes : attrs
      end

      private
    end

    module ClassMethods
      attr_accessor :arkenstone_url, :arkenstone_attributes, :arkenstone_content_type, :arkenstone_hooks, :arkenstone_inherit_hooks

      def url(new_url)
        self.arkenstone_url = new_url
      end

      def query_url
        "#{full_url(self.arkenstone_url)}query"
      end

      def add_hook(hook)
        self.arkenstone_hooks = [] if self.arkenstone_hooks.nil?
        self.arkenstone_hooks << hook
      end

      def inherit_hooks(val = true)
        self.arkenstone_inherit_hooks = val
      end

      def attributes(*options)
        self.arkenstone_attributes = options
        class_eval("attr_accessor :#{options.join(', :')}")
        return self.arkenstone_attributes
      end

      def content_type(new_content_type)
        self.arkenstone_content_type = new_content_type
      end

      def build(options)
        document = self.new
        document.attributes = options.select do |key, value|
          document.respond_to? :"#{key}="
        end
        return document
      end

      def parse_all(json)
        return [] if json.nil? or json.empty?
        tree = JSON.parse json
        documents = tree.map {|document| self.build document}
        Arkenstone::QueryList.new documents
      end

      def create(options)
        document = self.build(options)
        document.save
      end

      def find(id)
        url      = full_url(self.arkenstone_url) + id.to_s
        response = self.send_request url, :get
        return nil unless self.response_is_success response
        self.build JSON.parse(response.body)
      end

      # TODO: all of the http/network stuff is getting pretty big, I'd like to refactor it all out to its own module.
      def send_request(url, verb, data=nil)
        http = create_http url
        request_env = Arkenstone::Environment.new url: url, verb: verb, body: data
        call_request_hooks request_env
        request = build_request request_env.url, request_env.verb
        set_request_data request, request_env.body
        set_request_headers request, request_env.headers unless request_env.headers.nil?
        response = http.request request
        handle_response response
        response
      end

      def handle_response(response)
        if response_is_success response
          call_response_hooks response
        else
          call_error_hooks response
        end
      end

      def create_http(url)
        uri = URI(url)
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        http
      end

      def build_request(url, verb)
        klass = eval("Net::HTTP::#{verb.capitalize}")
        klass.new URI(url)
      end

      def set_request_data(request, data)
        case self.arkenstone_content_type
        when :form
          request.set_form_data data
        else
          data = data.to_json unless data.class == String
          request.body = data
          request.content_type = 'application/json'
        end
      end

      def set_request_headers(request, headers)
        headers.each do |key, val|
          request.add_field key, val
        end
      end

      def response_is_success(response)
        %w(200 204).include? response.code
      end

      def all
        response        = self.send_request self.arkenstone_url, :get
        documents       = parse_all response.body
        return documents
      end

      def where(query = nil, &block)
        body = build_where_body query, &block
        return nil if body.nil?
        response = self.send_request self.query_url, :post, body
        parse_all response.body if self.response_is_success response
      end

      def build_where_body(query = nil, &block)
        if query.class == String
          body = query
        elsif query.class == Hash
          body = query.to_json
        elsif query.nil? && block_given?
          builder = Arkenstone::QueryBuilder.new
          body = builder.build(&block)
        else
          nil
        end
      end

      def call_request_hooks(request)
        call_hook Proc.new { |h| h.before_request request }
      end

      def call_response_hooks(response)
        call_hook Proc.new { |h| h.after_complete response }
      end

      def call_error_hooks(response)
        call_hook Proc.new { |h| h.on_error response }
      end

      def call_hook(enumerator)
        hooks = []
        if self.arkenstone_inherit_hooks == true
          self.ancestors.each do |klass|
            break if klass == Arkenstone::Associations::InstanceMethods
            hooks.concat klass.arkenstone_hooks unless klass.arkenstone_hooks.nil?
          end
        else
          hooks = self.arkenstone_hooks
        end
        hooks.each(&enumerator) unless hooks.nil?
      end
    end
  end
end

