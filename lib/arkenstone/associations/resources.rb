module Arkenstone
  module Associations
    module Resources
      class << self
        def included(base)
          base.extend ClassMethods
        end
      end

      module ClassMethods
      end
    end
  end
end
