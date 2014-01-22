module Arkenstone
  class Environment
    attr_accessor :url, :verb, :body

    def initialize(options)
      options.each do |key, value|
        self.send("#{key}=".to_sym, value) if self.respond_to? key
      end
    end

    def build_request
      klass = eval("Net::HTTP::#{@verb.capitalize}")
      request = klass.new URI(@url)
      request.body = body unless @body.nil?
      request
    end
  end
end
