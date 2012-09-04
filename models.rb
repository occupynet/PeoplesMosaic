class Campaign
  include MongoMapper::Document
  key :slug, String, :required => true
  key :title, String, :required => true
  key :edit_link, String, :required => true
  key :description, String
  key :description_link, String
  key :start_timestamp, Integer
  key :end_timestamp, Integer
  key :ordering_key, String
  key :ordering_dir, String
  key :cover_image, String
  #any other conditions, as a mongo doc
end

#join table
class CampaignTweet
  include MongoMapper::Document
  key :campaign_id, ObjectId
  key :tweet_id, ObjectId
  timestamps!
  
end

class Tweet
  include MongoMapper::Document
  def removeIds
    
  end

  def removeRetweets
    
  end

  def expand_urls!
    self['entities']['urls'].each do |url|
      begin 
         url['expanded_url'].expand_urls!
       rescue NoMethodError
         url['expanded_url'] = ''
       end
    end
    self.save
  end

  def add_timestamp!
    
  end

end

#a search term, for crawler.  campaign_id, start_time, end_time
class Term
  include MongoMapper::Document
  key :campaign_id, ObjectId
  key :start_time, Time
  key :end_time, Time
  timestamps!
end

#just a collection of user ids that are blocked
class BlockedUser
  include MongoMapper::Document
end
