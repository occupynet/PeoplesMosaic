require 'rubygems'
require 'mongo_mapper'
require 'twitter'
require 'hpricot'
require 'haml'
require 'open-uri'
require 'time'
require 'mm-sluggable'
require 'youtube_it'
require 'vimeo'

require '/Users/thomasgillis/dev/ruby-dev/peoplesmosaic/config.rb'
#require 'crawler/crawler.rb'

#mongo
MongoMapper::connection = Mongo::Connection.new(@db_server)
MongoMapper::database = @db_name


#mongodb collection classes
require '/Users/thomasgillis/dev/ruby-dev/peoplesmosaic/models.rb'
Twitter.configure do |config|
  config.consumer_key = @twitter_consumer 
  config.consumer_secret = @twitter_consumer_secret
  config.oauth_token = @twitter_oauth_token
  config.oauth_token_secret = @twitter_oauth_secret
end


while 1
  @campaigns = Campaign.all({:end_timestamp=>{'$gte'=> Time.now.to_i}})
  puts @campaigns
  @campaigns.each do |c|
    c.update_media
    sleep 60
  end
end
