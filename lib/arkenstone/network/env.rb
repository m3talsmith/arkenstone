# frozen_string_literal: true

module Arkenstone
  # Environment is a wrapper around most of the properties created in a network request.
  # A raw net/http object doesn't allow for much customization after it is instantiated. This allows the caller to manipulate data via hooks before a request is created.
  class Environment
    attr_accessor :url, :verb, :body, :headers

    def initialize(options)
      options.each do |key, value|
        send("#{key}=".to_sym, value) if respond_to? key
      end
    end

    def to_s
      "#{@verb} #{@url}\n#{@body}"
    end
  end
end
