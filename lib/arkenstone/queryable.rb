# frozen_string_literal: true

module Arkenstone
  module Queryable
    class << self
      def included(base)
        base.extend Arkenstone::Queryable::ClassMethods
      end
    end

    module ClassMethods
      def query_url
        "#{full_url(arkenstone_url)}query"
      end

      def where(query = nil, &block)
        check_for_url
        body = build_where_body query, &block
        return nil if body.nil?

        # TODO: - refactor the network stuff into it's own module, so that we don't have `self` here
        response = send_request query_url, :post, body
        parse_all response.body if Arkenstone::Network.response_is_success response
      end

      def build_where_body(query = nil, &block)
        if query.instance_of?(String)
          body = query
        elsif query.instance_of?(Hash)
          body = query.to_json
        elsif query.nil? && block_given?
          builder = Arkenstone::QueryBuilder.new
          body = builder.build(&block)
        end
      end
    end
  end
end
