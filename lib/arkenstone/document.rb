require 'json'

module Arkenstone
  module Document
    class << self
      def included(base)
        base.send :include, Arkenstone::Document::InstanceMethods
        base.extend Arkenstone::Document::ClassMethods
        base.send :include, Arkenstone::Associations::InstanceMethods
        base.extend Arkenstone::Associations::ClassMethods
      end
    end

    module InstanceMethods
      attr_accessor :arkenstone_json, :arkenstone_attributes, :id

      def attributes
        new_hash = {}
        self.class.arkenstone_attributes.each do |key|
          new_hash[key.to_sym] = self.send("#{key}")
        end
        self.arkenstone_json = new_hash.to_json
        new_hash
      end

      def attributes=(options)
        self.arkenstone_json = options.to_json
        options.each do |key, value|
          self.send("#{key}=".to_sym, value) if self.respond_to? key
        end
        self.attributes
      end

      def to_json
        self.attributes.to_json
      end

      def save
        self.timestamp if self.respond_to?(:timestampable)
        response             = self.id ? put_document_data : post_document_data
        self.arkenstone_json = response.body
        self.attributes      = JSON.parse(response.body)
        return self
      end

      def update_attribute(key, value)
        hash = { key.to_sym => value }
        self.update_attributes hash
      end

      def update_attributes(new_attributes)
        original_attrs = self.attributes.clone
        attrs = self.attributes
        attrs.merge! new_attributes
        self.attributes = attrs
        if self.class.method_defined? :valid?
          if self.valid?
            self.save
          else
            self.attributes = original_attrs
            false
          end
        else
          self.save
        end
      end

      def instance_url
        "#{self.class.arkenstone_url}#{id}"
      end

      def class_url
        self.class.arkenstone_url
      end

      def post_document_data
        http_response class_url, :post
      end

      def put_document_data
        http_response instance_url, :put
      end

      def destroy
        resp = http_response instance_url, :delete
        self.class.response_is_success resp
      end

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
      attr_accessor :arkenstone_url, :arkenstone_attributes, :arkenstone_content_type, :arkenstone_hooks

      def url(new_url)
        self.arkenstone_url = new_url
      end

      def add_hook(hook)
        self.arkenstone_hooks = [] if self.arkenstone_hooks.nil?
        self.arkenstone_hooks << hook
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
        document.attributes = options
        return document
      end

      def parse_all(json)
        return [] if json.nil? or json.empty?
        tree = JSON.parse json
        tree.map {|document| self.build document}
      end

      def create(options)
        document = self.build(options)
        document.save
      end

      def find(id)
        url      = self.arkenstone_url + id.to_s
        response = self.send_request url, :get
        return nil unless self.response_is_success response
        self.build JSON.parse response.body
      end

      # body is a string or a Proc that returns a string
      def send_request(url, verb, data=nil)
        uri = URI(url)
        http = Net::HTTP.new(uri.hostname, uri.port)
        http.use_ssl = true if uri.scheme == 'https'
        env = Arkenstone::Environment.new url: url, verb: verb, body: data
        self.call_request_hooks env
        request = build_request env.url, env.verb
        set_request_data request, env.body
        response = http.request request
        self.call_response_hooks response
        response
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
          request.body = data.to_json
          request.content_type = 'application/json'
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

      def call_request_hooks(request)
        hooks = self.arkenstone_hooks
        enumerator = Proc.new { |h| h.before_request request }
        hooks.each(&enumerator) unless hooks.nil?
      end

      def call_response_hooks(response)
        enumerator = Proc.new { |h| h.after_complete response }
        hooks = self.arkenstone_hooks
        hooks.each(&enumerator) unless hooks.nil?
      end
    end
  end
end

