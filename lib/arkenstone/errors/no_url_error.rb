class NoUrlError < StandardError

  class << self
    def default_message
      'A `url` must be defined for the class.'
    end
  end
end
