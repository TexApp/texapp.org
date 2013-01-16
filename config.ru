require './application'
require 'sinatra'
set :environment, :development
use Rack::Deflater
run TexAppOrg
