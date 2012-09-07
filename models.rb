class Campaign
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Sluggable
  sluggable :name
  key :slug, String, :required => true
  key :name, String, :required => true
  key :edit_link, String, :required => true
  key :description, String
  key :conditions
  key :description_link, String
  key :start_timestamp, Integer
  key :end_timestamp, Integer
  key :bamp, String
  key :ordering_key, String
  key :ordering_dir, String
  key :cover_image, String
  #any other conditions, as a mongo doc

  def build_edit_link
    #if no edit link
    if self.edit_link ==nil
      (0...31).map{65.+(rand(52)).chr}.join
    end
  end
end

#join table
class CampaignMedia
  include MongoMapper::Document
  key :campaign_id, ObjectId
  key :media_id, ObjectId
  key :media_type, String
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
