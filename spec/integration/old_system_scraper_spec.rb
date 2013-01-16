require 'spec_helper'
require_relative '../../lib/scraper/old_system_scraper'
require 'date'

describe Scraper::OldSystemScraper, :integration do
  COURT = 3

  subject do
    Scraper::OldSystemScraper.new(COURT)
  end

  it "scrapes opinions for a given date" do
    date = Date.new 2011, 1, 13
    opinions = []
    subject.scrape(date) { |x| opinions << x }
    opinions.length.should == 1
    opinions.all? { |x| x.instance_of? Hash }.should be_true
    o = opinions.first
    o[:case][:docket_number].should == '03-10-00280-CV'
    o[:date].should == date
    o[:url].should == 'http://www.3rdcoa.courts.state.tx.us/opinions/pdfOpinion.asp?OpinionID=19906'
    o[:case][:court].should == 3
  end
end
