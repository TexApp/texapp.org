require_relative "scraper/old_system_scraper"
require_relative "scraper/tames_scraper"
require_relative "scraper/courts"
require_relative "scraper/cacher"

module Scraper
  def self.for court_number, delay=nil
    court = COURTS[court_number]
    Scraper.const_get(court['scraper']).new court_number, delay
  end
end
