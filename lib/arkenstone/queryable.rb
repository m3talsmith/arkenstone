module Arkenstone
  module Queryable

    class << self
      def included(base)
        base.extend Arkenstone::Queryable::ClassMethods
      end
    end

    module ClassMethods
      def query_url
        "#{full_url(self.arkenstone_url)}query"
      end

      def where(query = nil, &block)
        body = build_where_body query, &block
        return nil if body.nil?
        # TODO - refactor the network stuff into it's own module, so that we don't have `self` here
        response = self.send_request self.query_url, :post, body
        parse_all response.body if Arkenstone::Network.response_is_success response
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

    end
  end
end
