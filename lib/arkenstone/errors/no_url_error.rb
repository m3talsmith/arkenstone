# frozen_string_literal: true

# Raised if an Arkenstone document does not have a URL associated with it. A URL is set with the +url+ directive:
#
#    class Widget
#      url 'http://example.com/widgets'
#    end
class NoUrlError < StandardError
  class << self
    def default_message
      'A `url` must be defined for the class.'
    end
  end
end
