require 'rubygems'
require 'sinatra'
require 'mongo_mapper'
require 'twitter'
require 'hpricot'
require 'haml'
require 'open-uri'
require 'config.rb'

#require 'crawler/crawler.rb'
require 'mosaic/mosaic.rb'

#mongo
MongoMapper::connection = Mongo::Connection.new(@db_server)
MongoMapper::database = @db_name

#mongodb collection classes
require 'models.rb'


Twitter.configure do |config|
  config.consumer_key = @twitter_consumer 
  config.consumer_secret = @twitter_consumer_secret
  config.oauth_token = @twitter_oauth_token
  config.oauth_token_secret = @twitter_oauth_secret
end

#a homepage of mosaics, with a representative image (pinterest style :/ )
get '/' do
  @campaigns = Campaign.all({:order=>'conditions.start_time'.to_sym.asc})
  haml :index
end
#copy all other dbs to this one
  #ows - chicagonato
  #ows - quebec
  #backtrace - silentmarch
  #local - n17
  


