require 'active_support/inflector'

module Arkenstone
  module Associations
    # has_many :children creates the following methods on instances of the class
    # children() -- which always fetches from the server
    # children_cached() -- which returns what was last fetched from the server
    # add_child(child) -- adds on the server. child is either an object or id
    # remove_child(child) -- removes from the server. child is either an object or id
    
    module ClassMethods
      def has_many(child_model_name)
        define_method(child_model_name) do # back in the instance scope
          @association_data = {} if @association_data.nil?
          @association_data[child_model_name] = fetch_children child_model_name
          @association_data[child_model_name]
        end
      end

    end

    module InstanceMethods
      def fetch_children(child_model_name)
        # GET parent_name/:id/child_names
        # child model == Thing
        url = build_nested_url child_model_name
        response = self.class.send_request url, :get
        klass_name = child_model_name.to_s.classify
        klass = Kernel.const_get klass_name
        klass.parse_all response.body
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
