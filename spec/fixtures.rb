def fixture(file) "spec/fixtures/#{file}" end

BASE = 'http://www.3rdcoa.courts.state.tx.us/opinions'
def url(suffix) "#{BASE}/#{suffix}" end

def fake page, response
  page = url page
  response = fixture response
  `curl -is '#{page}' > '#{response}'` unless File.exist? response
  FakeWeb.register_uri :get, page, :response => File.read(response)
end

def fake_case id
  fake "case.asp?FilingID=#{id}", "case-3-#{id}"
end

def fake_event id
  fake "event.asp?EventID=#{id}", "event-3-#{id}"
end

def fake_docket date
  date_string = date.strftime '%Y%m%d'
  fake "docket.asp?FullDate=#{date_string}", "docket-3-#{date_string}"
end
