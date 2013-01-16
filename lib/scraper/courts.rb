require 'yaml'

module Scraper
  DATA_DIR = File.join(File.dirname(__FILE__), '..', '..', 'data')
  COURTS = YAML::load_file(File.join(DATA_DIR, 'courts.yml'))
end
