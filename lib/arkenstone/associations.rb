require 'active_support/inflector'

module Arkenstone
  module Associations
    module ClassMethods
      def has_many(child_model_name)
        cached_child_name = "cached_#{child_model_name}"
        define_method(cached_child_name) do
          @association_data = {} if @association_data.nil?
          if @association_data[child_model_name].nil?
            @association_data[child_model_name] = fetch_children child_model_name
          end
          @association_data[child_model_name]
        end

        define_method(child_model_name) do # back in the instance scope
          @association_data = {} if @association_data.nil?
          @association_data[child_model_name] = nil
          self.send cached_child_name.to_sym
        end

        singular = child_model_name.to_s.singularize
        add_child_method_name = "add_#{singular}"
        define_method(add_child_method_name) do |new_child|
          @association_data = {} if @association_data.nil?
          self.add_child child_model_name, new_child.id
          @association_data[child_model_name] = nil
          self.send cached_child_name.to_sym
        end

        remove_child_method_name = "remove_#{singular}"
        define_method(remove_child_method_name) do |child_to_remove|
          @association_data = {} if @association_data.nil?
          self.remove_child child_model_name, child_to_remove.id
          @association_data[child_model_name] = nil
          self.send cached_child_name.to_sym
        end
      end

    end

    module InstanceMethods
      def fetch_children(child_model_name)
        url = build_nested_url child_model_name
        response = self.class.send_request url, :get
        klass_name = child_model_name.to_s.classify
        klass = Kernel.const_get klass_name
        klass.parse_all response.body
      end

      def add_child(child_model_name, child_id)
        url = build_nested_url child_model_name
        body = {id: child_id}.to_json
        self.class.send_request url, :post, body
      end

      def remove_child(child_model_name, child_id)
        url = build_nested_url child_model_name, child_id
        self.class.send_request url, :delete
      end

      private
      def build_nested_url(child_name, child_id = nil)
        url = "#{self.instance_url}/#{child_name}"
        url += "/#{child_id}" unless child_id.nil?
        url
      end

    end
  end

end
