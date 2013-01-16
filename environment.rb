require 'rubygems'
require 'bundler/setup'

require 'yaml'
CONF = File.join(File.dirname(__FILE__), 'config', 'credentials.yml')
CREDENTIALS = YAML.load_file CONF

require_relative './lib/models'
DataMapper.setup(:default, CREDENTIALS['database'])

require 'cloudfiles'
$cloudfiles = CloudFiles::Connection.new(
  CREDENTIALS['cloudfiles'].reduce({}) do |mem, pair|
    mem[pair[0].to_sym] = pair[1]
    mem
  end
)

CONTAINER = CREDENTIALS['container']

require 'sinatra' unless defined?(Sinatra)
