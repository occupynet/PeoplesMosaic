class Campaign
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Sluggable
  sluggable :name
  many :terms
  key :page_title
#  deprecated?
#  key :slug, String, :required => true
  key :name, String, :required => true
  key :edit_link, String, :required => true
  key :description, String
  key :conditions
  key :description_link, String
  key :start_timestamp
  key :end_timestamp
  key :bamp, String
  key :ordering_key, String
  key :ordering_dir, String
  key :cover_image, String
  key :media_count
  #any other conditions, as a mongo doc




  def update_media
    @search_terms = Term.all({:conditions=>{:campaign_id=>self.id}})
    puts @search_terms.inspect
    @search_terms.each do |term|
      puts term.inspect
      #get the tweets from the internet
      #do formatting, link expansion etc in this method
      #save the tweet
      tweets = term.crawl
      since_id = ''
      tweets.each do |tweet|
        #does it conform to campaign settings (has media?)
        if tweet["entities"] && tweet["entities"]["media"]
          puts tweet.inspect
          #build a campaingn tweet object
          ct = CampaignMedia.new
          ct.media_id = tweet.id_str
          ct.campaign_id = self.id
          ct.ordering_key = tweet.timestamp
          #save it 
          ct.save
        end
        since_id = tweet.id_str
      end
      #update since time for term
      #update since id for highest tweet id crawled
      puts since_id
      term.since_id = since_id
      term.last_checked = Time.now
      term.save
    end
    self.media_count = CampaignMedia.count({:campaign_id=>self.id}) 
    self.save
  end




  def build_edit_link
    #if no edit link
    if self.edit_link ==nil
      (0...31).map{97.+(rand(26)).chr}.join
    end
  end
end

#join table
class CampaignMedia
  include MongoMapper::Document
  belongs_to :campaign
  belongs_to :tweet
  key :campaign_id, ObjectId
  key :media_id
  key :media_type, String
  key :ordering_key 
  timestamps!
  
  
  def save_from_url (url, edit_link)
    c = Campaign.first({:edit_link=>edit_link})
    if (c.slug !=nil)
      self.campaign_id = c.id
      self.ordering_key = 'timestamp'

      if (url.split("twitter.com").size >1)
        #ugly split
        id = url.split("twitter.com")[1].split("/")[4]
        a_tweet = Twitter.status(id).attrs
        self.media_type = 'twitter'
        a.tweet['id_str'] = a_tweet['id'].to_s
        a_tweet.id=nil
        Tweet.collection.update({:id_str=>a_tweet["id_str"].to_s},a_tweet, {:upsert => true})
        #now view the tweet
        self.media_id = a_tweet['id_str']
        self.save
        @tweet = a_tweet["text"]
      else
        #if not, parse what we can with hpricot and just save the whole page
        html = ""
        open(url) {|f|
          f.each_line {|line| html << line}
        }
        domain = url.split("/")[2]
        @html = Hpricot(html)
        title = (@html/"title")[0].inner_html
        #bookmarked so we know it was intentionally saved, not crawled
        Tweet.collection.update({:url=>params[:url]}, {:html=>html, :url=>params[:url],:title=>title, :id_str=>url, :origin=>domain,:bookmarked=>true}, {:upsert => true}) 
        self.media_type = domain
        self.media_id = url
        @tweet = title
      end
      @tweet
    end
  end
  
end

class Tweet
  include MongoMapper::Document
  key :ows_meta_tags, Array
  def removeIds
    
  end

  def removeRetweets
    
  end
  
  def build_hashtag_array
    tags = []
    if ( (! self.entities.empty?)  && self['entities']['hashtags'] !=nil)
      self['entities']['hashtags'].each do |tag|
        tags << tag['text']
      end
    end
    self.ows_meta_tags = tags
  end
  
  #tweetstache - crawl and save media from a url
  
  
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
  key :term, String
  key :start_time, Time
  key :end_time, Time
  key :since_id, String
  key :last_checked, Time
  belongs_to :campaign
  timestamps!
  
  
  def crawl
    @blocked = BlockedUser.all
    @block = {}
    sleep 1
    @blocked.each do |block|
      @block[block["user_id"]] = block["user_id"]
    end
    @tweets = []
    puts self.term
    d = Time.at(self.campaign.end_timestamp).to_datetime
    #only do this if current time is before campaign.end_timestamp
    date_until = [d.year, d.month, ((d.day.to_i)+1).to_s].join('-').to_s
     15.times do |p|
       begin 
         #campaign.since_id, campaign.end_date
         query = {:rpp=>100, :page => (p+1).to_i,:since_id =>self.since_id, :until=>date_until,:include_entities=>1}
         tweets = Twitter.search(self.term.to_s + " -rt", query)
       rescue
         puts "bad gateway"
         sleep 30
         tweets = Twitter.search(self.term.to_s + " -rt", query)   
       end
       begin 
         puts tweets.size
       rescue NoMethodError
         tweets = []
       end
       if tweets.size==0
         break
       end
         
       tweets.each do | a_tweet |
         #add an integer timestamp
         begin 
           a_tweet.attrs["timestamp"] = Time.parse(a_tweet.attrs["created_at"]).to_i
         rescue NoMethodError
           a_tweet.attrs["timestamp"] = 1
         end
   
         #extract vids for embed code
         if a_tweet.attrs["entities"]
           if a_tweet.attrs["entities"]["urls"] !=nil
           a_tweet.attrs["entities"]["urls"].each do |url|
             3.times do |x|
               begin 
                 url["expanded_url"].expand_urls!
               rescue NoMethodError
                 url["expanded_url"] = ""
               end
             end
             if url["expanded_url"].split("youtube.com").size >1 || url["expanded_url"].split("youtu.be").size > 1
               client = YouTubeIt::Client.new(:dev_key => @devkey)
               begin 
                 vid = client.video_by(url["expanded_url"])
                 a_tweet.attrs["video_embed"] = vid.embed_html
               rescue OpenURI::HTTPError => e
               
               end
             
             #vimeo 
             elsif (url["expanded_url"].split("vimeo.com").size > 1)
               video_id = url["expanded_url"].split("/").last
               vid = Vimeo::Simple::Video.info(video_id)
               a_tweet.attrs["video_embed"] =  '<iframe src="http://player.vimeo.com/video/#{vid.id}" width="500" height="313" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>'
         
             #ht.ly is only used by porn spammers
             elsif (url["expanded_url"].split("ht.ly").size > 1)
               a_tweet.attrs["block"] =1
             #manually grab instagrams for the thumbnail
             elsif (url["expanded_url"]).split("instagr.am").size > 1
               begin OpenURI::HTTPError
               #add the media link
                 html = ""
                 open(url["expanded_url"]) {|f|
                   f.each_line {|line| html << line}
                 }
                @html = Hpricot(html)
                a_tweet.attrs["entities"]["media"] = [:media_url=>(@html/"img.photo")[0][:src] , :expanded_url=>  (@html/"img.photo")[0][:src],:size=>{:small=>{:h=>320}}]
               rescue 
               end
             end
           end
         end
         end

         #block this tweet if the user is in the blocked list
         if @block[a_tweet.attrs["from_user_id"].to_s] !=nil
           a_tweet.attrs["block"] = 1
         end
         begin 
           #kill the twitter ID so we get a mongoID object instead
           a_tweet.attrs['id'] = nil  
           #save / update
           Tweet.collection.update({:id_str=>a_tweet.attrs["id_str"].to_s},a_tweet.attrs, {:upsert => true})
           tweet =  Tweet.first({:id_str=>a_tweet.attrs["id_str"].to_s})
           tweet.build_hashtag_array
           @tweets << tweet
         rescue  
         end
       end
     end
  #return the list of tweets to save CampaignMedia objects
  @tweets
  end
end

#just a collection of user ids that are blocked
class BlockedUser
  include MongoMapper::Document
  #purge all existing media from this user
  def purge
  end
  
  
end


#indexes
Tweet.ensure_index(:timestamp)
Tweet.ensure_index([[:id_str,1]], :unique=>true)
CampaignMedia.ensure_index(:media_id)
CampaignMedia.ensure_index(:campaign_id)
CampaignMedia.ensure_index([[:media_id, 1],[:campaign_id,1]],:unique=>true)
CampaignMedia.ensure_index([[:ordering_key,1]])
CampaignMedia.ensure_index([[:ordering_key,-1]])


class NewTweet
  include MongoMapper::Document
  key :media_id
  def cleanup
    @cm = CampaignMedia.all({:order=>'media_id.asc'.to_sym})
    @cm.each do |cm|
      ct = CampaignMedia.all({:media_id =>cm[:media_id]})
      x = ct.size-1
      ct[1..x].each {|p|p.destroy}
    end
    
    @prev_id="A"
    @cm = CampaignMedia.all({:order=>'media_id.asc'.to_sym})
    @cm.each do |cm|
      if cm.media_id == @prev_id
        NewTweet.collection.update({:media_id=>cm.media_id}, {:twid=>cm.id, :media_id=>cm.media_id},{:upsert=>true})
      end
      @prev_id = cm.media_id
    end
    @nt = NewTweet.all
    @nt.each do |tw|
      cm = CampaignMedia.first(:id=>tw[:twid])
      cm.destroy
    end
  end
end

