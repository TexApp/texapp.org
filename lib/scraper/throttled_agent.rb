require 'mechanize'

module Scraper
  class ThrottledAgent < Mechanize
    attr_accessor :delay

    def initialize delay
      super()
      self.user_agent_alias = 'Windows IE 9'
      self.max_history = 0
      @delay = delay
    end

    def fetch
      sleep @delay
      super
    end
  end
end
