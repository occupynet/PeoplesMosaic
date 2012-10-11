
require 'rubygems'
require 'sinatra'
require 'mongo_mapper'
require 'twitter'
require 'hpricot'
require 'haml'
require 'open-uri'
require 'time'
require 'mm-sluggable'
require 'youtube_it'
require 'vimeo'
require File.expand_path(File.dirname(__FILE__)+'/lib/expand_url.rb')

require File.expand_path(File.dirname(__FILE__)+'/config.rb')

class Sinatra::Base
set :protection, :except => :frame_options
end

#mongo
MongoMapper::connection = Mongo::Connection.new(@db_server)
MongoMapper::database = @db_name


class Float
  def clip(max)
    self > max ? max : self  
  end
end


#mongodb collection classes
require '/Users/thomasgillis/dev/ruby-dev/peoplesmosaic/models.rb'
Twitter.configure do |config|
  config.consumer_key = @twitter_consumer 
  config.consumer_secret = @twitter_consumer_secret
  config.oauth_token = @twitter_oauth_token
  config.oauth_token_secret = @twitter_oauth_secret
end

require '/Users/thomasgillis/dev/ruby-dev/peoplesmosaic/mosaic/mosaic.rb'

#a homepage of mosaics, with a representative image (pinterest style :/ )
get '/' do
  
  undordered_campaigns = Campaign.all({:order=>'start_timestamp'.to_sym.desc,:conditions=>{:front_page=>'yes'}})
  @campaigns = []
  undordered_campaigns.each do |campaign|
    score = 0
    score = CampaignMedia.count({:order=>'ordering_key'.to_sym.desc, :limit=>50, 
      :conditions=>{:campaign_id => campaign.id, :ordering_key=>{'$gte'=>Time.now.to_i-86400}}})
    score = score * 10
    score = score + CampaignMedia.count({:order=>'ordering_key'.to_sym.desc, :limit=>50, 
      :conditions=>{:campaign_id => campaign.id, :ordering_key=>{'$gte'=>Time.now.to_i-(86400*5)}}})
      campaign['activity_score'] = score
    @campaigns<<campaign
  end
  haml :index
end
