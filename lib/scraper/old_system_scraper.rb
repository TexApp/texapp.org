require_relative 'throttled_agent'
require_relative 'courts'

module Scraper
  class OldSystemScraper
    THROTTLE_DELAY = 1

    def initialize court, delay=THROTTLE_DELAY
      delay = 0 if delay == :no_throttling
      @court = court
      @agent = ThrottledAgent.new delay
      @court_number = court
      @court = Scraper::COURTS[court]
      @base = @court['site'] + "/opinions"
    end

    def scrape date
      cases_with_opinions_on_day(date).each do |docket_number, case_id|
        opinions_for_case(case_id) { |o| yield o }
      end
    end

    def pdf_url opinion_id
      "#{@base}/pdfOpinion.asp?OpinionID=#{opinion_id}"
    end

    EVENT_KEY = 'EventID'
    OPINION_LINK_XPATH = './/*[@id="content-middle2"]/table/tr[2]/td/table[2]/tr[2]/td[1]/a'
    OPINION_LINK_RE = /Opinion\.asp\?OpinionID=(\d+)/
    def opinion_id event_id
      url = "#{@base}/event.asp"
      page = @agent.get url, { EVENT_KEY => event_id }
      link = page.link_with :href => OPINION_LINK_RE
      OPINION_LINK_RE.match(link.href)[1].to_i
    end

    QUARTER_KEYS = %w{DocketYear Yr_Quarter}
    CASE_TD = './/*[@id="content-middle2"]/table[2]/tr[position()>1]/td[2]'
    def opinions_in_quarter year, quarter
      url = "#{@base}/docketsrch.asp"
      page = @agent.get url, Hash[QUARTER_KEYS.zip [year, quarter]]
      page.search(CASE_TD).to_a.map do |td|
        Date.strptime td.text, '%m/%d/%Y'
      end
    end

    DAY_KEY = 'FullDate'
    CASE_LINK_RE = %r{/opinions/case\.asp\?FilingID=(\d+)}
    def cases_with_opinions_on_day day
      url = "#{@base}/docket.asp"
      page = @agent.get url, { DAY_KEY => day.strftime("%Y%m%d") }
      page.links_with(:href => CASE_LINK_RE).reduce({}) do |mem, link|
        case_id = CASE_LINK_RE.match(link.href)[1].to_i
        mem.merge({ link.text => case_id })
      end
    end

    CASE_KEY = 'FilingID'
    def opinions_for_case case_id
      url = "#{@base}/case.asp"
      page = @agent.get url, { CASE_KEY => case_id }
      the_case = case_metadata page
      yield_opinions page do |o|
        yield ({
          :case => the_case,
          :date => o[:date],
          :type => o[:type],
          :url => pdf_url(o[:id])
        })
      end
    end

    ROW_XPATH = './/*[@id="content-middle2"]/table/tr[2]/td/table[2]/tr'
    OPINION_TYPES = {
      "Memorandum opinion issued" => :memorandum,
      "Opinion issued" => :opinion
    }
    EVENT_RE = %r{event\.asp\?EventID=(\d+)$}
    def yield_opinions page
      page.search(ROW_XPATH).to_a.slice(1..-2).each do |row|
        tds = row.search('.//td').to_a
        type = tds[2].text.strip
        if OPINION_TYPES.keys.include? type
          date = Date.strptime tds[1].text.strip, '%m/%d/%Y'
          href = row.css('a').first.attr('href')
          event_id = EVENT_RE.match(href)[1].to_i
          yield ({
            :type => OPINION_TYPES[type],
            :date => date,
            :id => opinion_id(event_id)
          })
        end
      end
    end

    META = '//*[@id="content-middle2"]/table/tr[2]/td/table[1]/tr/td/table/tr'
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
        key = tr.at_css('td.BreadCrumbs').text
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
