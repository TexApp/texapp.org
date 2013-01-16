require 'data_mapper'

class Case
  include DataMapper::Resource
  property :id, Serial
  property :court, Integer
  property :docket_number, String, :index => true
  property :style, Text

  has n, :opinions
end

class Opinion
  include DataMapper::Resource
  property :id, Serial
  property :date, Date
  property :type, String
  property :url, Text
  property :md5sum, String, :length => 32
  
  belongs_to :case

  # CloudFiles file name
  def self.filename_for docket_number, checksum
    "#{checksum}/#{docket_number}.pdf"
  end

  def filename
    Opinion.filename_for self.case.docket_number, @md5sum
  end
end

class Log
  include DataMapper::Resource
  property :id, Serial
  property :court, Integer
  property :date, Date
end

DataMapper::Model.raise_on_save_failure = true
DataMapper.finalize
