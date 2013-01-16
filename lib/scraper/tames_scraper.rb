require_relative 'throttled_agent'
require_relative 'courts'

module Scraper
  class TAMESScraper
    THROTTLE_DELAY = 3

    BASE = 'http://www.search.txcourts.gov'

    def initialize court, delay=THROTTLE_DELAY
      delay = 0 if delay == :no_throttling
      @court = court
      @agent = ThrottledAgent.new delay
      @court_number = court
      @court = Scraper::COURTS[court]
    end

    def scrape date
      cases_with_opinions_on_day(date).each do |docket_number|
        opinions_for_case(docket_number) do |o|
          yield o
        end
      end
    end

    DAY_KEY = 'FullDate'
    CASE_LINK_RE = %r{Case\.aspx\?cn=(\d\d-\d\d-\d\d\d\d\d-..)}
    def cases_with_opinions_on_day day
      url = "#{BASE}/Docket.aspx"
      params = {
        :coa => format("coa%02d", @court_number),
        :FullDate => day.strftime('%m/%d/%Y'),
        :p => 1
      }
      page = @agent.get url, params
      page.links_with(:href => CASE_LINK_RE).map do |link|
        CASE_LINK_RE.match(link.href)[1]
      end.uniq
    end

    CASE_URL = "#{BASE}/Case.aspx"
    def opinions_for_case docket_number
      page = @agent.get CASE_URL, { :cn => docket_number, :p => 1 }
      the_case = case_metadata page
      yield_opinions page do |o|
        yield ({
          :case => the_case,
          :date => o[:date],
          :type => o[:type],
          :url => o[:url]
        })
      end
    end

    OPINION_TYPES = {
      'Opinion issued' => :opinion,
      'Memorandum opinion issued' => :memorandum
    }
    def yield_opinions page
      page.search('.//tr[@class="rgRow" or @class="rgAltRow"]').each do |row|
        tds = row.search('./td').to_a
        type = tds[1].text
        next unless tds.count == 5
        if OPINION_TYPES.keys.include? type
          links = tds[4]
          date = Date.strptime tds[0].text.strip, '%m/%d/%Y'
          links.search('.//tr').each do |linkrow|
            label = linkrow.css('td').first.text
            if /opinion/i =~ label
              yield ({
                :type => OPINION_TYPES[type],
                :date => date,
                :url => BASE + '/' + linkrow.css('a').attr('href')
              })
            end
          end
        end
      end
    end

    META = '//*[@id="ctl00_ContentPlaceHolder1_tblContent"]//tr[2]/td/table//tr/td/table//tr[3]/td/table//tr/td/table//tr'
    META_KEYS = {
      'Case Number:' => :docket_number,
      'Style:' => :style,
      'v.:' => :versus
    }
    META_FORMAT = {
      :filed => lambda { |x| Date.strptime(x, '%m/%d/%Y')}
    }
    def case_metadata page
      meta = {}
      page.search(META).to_a.each do |tr|
        key = tr.at_css('td.BreadCrumbs').text.strip
        next unless META_KEYS.keys.include? key
        value = tr.at_css('td.TextNormal').text.gsub("\u00A0"," ").strip
        meta_key = META_KEYS[key]
        format = META_FORMAT[meta_key]
        meta[meta_key] = format.nil? ? value : format.call(value)
      end
      if meta[:versus] && meta[:versus].length > 0
        meta[:style] = "#{meta[:style]} v. #{meta[:versus]}"
      end
      return({
        :court => @court_number,
        :docket_number => meta[:docket_number],
        :style => meta[:style]
      })
    end
    
  end
end
