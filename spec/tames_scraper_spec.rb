require 'spec_helper'
require 'fixtures'
require 'fakeweb'
require 'yaml'
require 'date'

require_relative '../lib/scraper/tames_scraper'
describe Scraper::TAMESScraper do
  subject do
    Scraper::TAMESScraper.new 1, :no_throttling
  end

  before :all do
    FakeWeb.allow_net_connect = false
  end

  it "scrapes opinions issued on a particular day" do
    date = Date.new 2012, 12, 21
    FakeWeb.register_uri :get,
      'http://www.search.txcourts.gov/Docket.aspx?coa=coa01&FullDate=12%2F21%2F2012&p=1',
      :response => File.read('spec/fixtures/docket-1-20121221')
    %w{01-12-00584-CV 01-12-01013-CV 01-12-01022-CV}.each do |d|
      FakeWeb.register_uri :get,
        "http://www.search.txcourts.gov/Case.aspx?cn=#{d}&p=1",
        :response => File.read("spec/fixtures/case-#{d}")
    end
    expect { |b|
      subject.opinions_for_case "01-12-00584-CV", &b
    }.to yield_successive_args Hash, Hash
    expect { |b|
      subject.opinions_for_case "01-12-01022-CV", &b
    }.to yield_successive_args Hash
    expect { |b| 
      subject.scrape date, &b
    }.to yield_successive_args Hash, Hash, Hash, Hash
  end

  it "yields opinions" do
    d = "01-12-01013-CV"
    FakeWeb.register_uri :get,
      "http://www.search.txcourts.gov/Case.aspx?cn=#{d}&p=1",
      :response => File.read("spec/fixtures/case-#{d}")
    expect { |b|
      subject.opinions_for_case "01-12-01013-CV", &b
    }.to yield_successive_args Hash
  end

  it "scrapes cases with opinions issued on a particular day" do 
    jan_10 = Date.new 2013, 1, 10
    FakeWeb.register_uri :get,
      'http://www.search.txcourts.gov/Docket.aspx?coa=coa01&FullDate=01%2F10%2F2013&p=1',
      :response => File.read('spec/fixtures/day-1-20130110')
    first  = YAML::load_file fixture "day-1-20130110.yml"
    subject.cases_with_opinions_on_day(jan_10).should =~ first
  end

  it "scrapes case information" do
    FakeWeb.register_uri :get,
      'http://www.search.txcourts.gov/Case.aspx?cn=01-11-01033-CV&p=1',
      :response => 'spec/fixtures/case-01-11-01033-CV'
    docket = '01-11-01033-CV'
    expect { |b|
      subject.opinions_for_case docket, &b
    }.to yield_successive_args Hash
    subject.opinions_for_case docket do |opinion|
      opinion[:date].should == Date.new(2013, 1, 10)
      opinion[:case][:style].should == 'CBM Engineers, Inc. v. Tellepsen Builders, L.P.'
      opinion[:case][:docket_number].should == docket
      opinion[:url].should == 'http://www.search.txcourts.gov/SearchMedia.aspx?MediaVersionID=1c397bf1-5614-4e9f-9ea6-27fcae54f159&coa=coa01&DT=Opinion&MediaID=66b50cee-207f-4fff-a765-3eee9c122a2d'
    end
  end
end
