module Arkenstone
  module Helpers
    class << self
      def included(base)
        base.send :include, Arkenstone::Helpers::GeneralMethods
        base.extend Arkenstone::Helpers::GeneralMethods
      end
    end

    module GeneralMethods
      def full_url(url)
        url =~ /(\/$)/ ? url : "#{url}/"
      end
    end
  end
end
