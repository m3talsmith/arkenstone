module Arkenstone
  class Yarra
    attr_accessor :elements

    def initialize(elements=[])
      @elements = elements
    end

    def <<(element)
      @elements << element
    end

    def to_s
      @elements
    end
  end
end
