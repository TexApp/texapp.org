require 'spec_helper'
require 'fixtures'
require 'fakeweb'
require 'yaml'
require 'date'

require_relative '../lib/scraper/old_system_scraper'
describe Scraper::OldSystemScraper do
  subject do
    Scraper::OldSystemScraper.new 3, :no_throttling
  end

  before :all do
    FakeWeb.allow_net_connect = false
  end
  
  context 'fully faked' do
    let :date do Date.new 2012, 1, 13 end

    before :all do
      fake_docket date
      fake_case 16389
      fake_event 446493
      fake_case 16817
      fake_event 446521
    end

    it "scrapes opinions for a given date" do
      expect { |b|
        subject.scrape date, &b
      }.to yield_successive_args Hash, Hash
    end

    it "returns proper values" do
      subject.scrape date do |o|
        o[:case][:docket_number].should be_instance_of String
        o[:case][:court].should be_instance_of Fixnum
        o[:case][:style].should be_instance_of String

        o[:date].should be_instance_of Date
        o[:type].should be_instance_of Symbol
        o[:url].should be_instance_of String
      end
    end
  end

  it "scrapes opinion IDs" do
    fake "event.asp?EventID=429162", "event-3-429162"
    subject.opinion_id(429162).should == 20092

    fake "event.asp?EventID=429114", "event-3-429114"
    subject.opinion_id(429114).should == 20090
  end

  it "scrapes quarterly opinion reports" do
    fake "docketsrch.asp?DocketYear=2011&Yr_Quarter=1", "quarter-3-2011-1"
    first = YAML::load_file fixture "quarter-3-2011-1.yml"
    subject.opinions_in_quarter(2011, 1).should =~ first

    fake "docketsrch.asp?DocketYear=2011&Yr_Quarter=2", "quarter-3-2011-2"
    second = YAML::load_file fixture "quarter-3-2011-2.yml"
    subject.opinions_in_quarter(2011, 2).should =~ second
  end

  it "scrapes opinions from a particular day" do 
    thirty_one = Date.new 2011, 3, 31
    fake_docket thirty_one
    first  = YAML::load_file fixture "day-3-20110331.yml"
    subject.cases_with_opinions_on_day(thirty_one).should == first

    eighteen = Date.new 2011, 3, 18
    fake_docket eighteen
    second = YAML::load_file fixture "day-3-20110318.yml"
    subject.cases_with_opinions_on_day(eighteen).should == second
  end

  it "scrapes opinions from cases" do
    fake_case 14902
    random = 1 + rand(2000)

    subject.should_receive(:opinion_id).with(428424).and_return(random)
    results = []
    subject.opinions_for_case(14902) { |x| results << x }
    results.count.should == 1
    results.first.should be_instance_of Hash
  end
end
