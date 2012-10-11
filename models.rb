class Campaign
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Sluggable
  sluggable :name
  belongs_to :theme
  many :terms
  key :page_title
  key :theme_id, ObjectId
#  deprecated?
#  key :slug, String, :required => true
  key :name, String, :required => true
  key :edit_link, String, :required => true
  key :front_page, String
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
      since_id = term.since_id
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
          ct.save!
          #and the aggreate table
          puts tweet.entities.inspect
          url = tweet["entities"]["media"][0]["media_url"]
          v = {:media_url=>url,
            :media_type=>"tweet", 
            :ordering_key=>ct.ordering_key,
            :media_id=>ct.media_id}
          AggregateMedia.collection.update({:media_url=>url},{'$set'=>v},{:upsert=>true})
          a = AggregateMedia.first({:media_url=>url})
          a.add_to_set(:campaign_id=>ct.campaign_id)
          a.add_to_set(:campaign_media_id=>ct.id)
          a.set(:score=>a.campaign_media_id.size)

        end
        since_id = tweet.id_str
      end
      #update since time for term
      #update since id for highest tweet id crawled
      puts since_id
      Term.collection.update({:id=>term.id},{'$set'=>{:since_id=>since_id,:last_checked=>Time.now}},{:upsert=>false})
#      term.since_id = since_id
#      term.last_checked = Time.now
#      term.save
    end
    #weird bug where a campaign would lose recently save-data.
    #suspect it was caused here, not sure
      Campaign.collection.update({:slug=>self.slug},  
      {'$set'=>{:media_count=>AggregateMedia.count({:hidden=>{'$exists'=>false},:campaign_id=>self.id})}})
   # self.save
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
  
  
  def aggregate_media
    #build an aggregate media collection
    # for each campaign
    #    scoop all media links
    #    upsert by media_url
    #      increment count of each insert, plus retweet score
    #      CM id in an array in aggregate media
    #      campaign id in aggregate media
    #reverse chronological order so the final aggrgated media key is the original tweet
    #skip the blocked media
    @campaigns = Campaign.all({:hidden=>{'$exists'=>false}})
    @campaigns.each do |campaign|
      cm = CampaignMedia.all({
        :conditions=>
          {:campaign_id=>campaign.id},
        :order=>[:ordering_key,'desc']})
      cm.each do |c|
        t = Tweet.first({:id_str=>c.media_id})
        begin
          url = t['entities']['media'][0]['media_url']
          v = {:media_url=>url,
            :media_type=>c.media_type, 
            :ordering_key=>c.ordering_key,
            :media_id=>c.media_id}
          AggregateMedia.collection.update({:media_url=>url},{'$set'=>v},{:upsert=>true})
          a = AggregateMedia.first({:media_url=>url})
          a.increment(:score=>1)
          a.add_to_set(:campaign_id=>c.campaign_id)
          a.add_to_set(:campaign_media_id=>c.id)
        rescue
        end
      end
    end
  end
  def build_collection 
  
    #get each campaign
    @campaigns = Campaign.all
    @campaigns.each do |campaign|
      terms = Term.all({:campaign_id=>campaign.id})
      tags = []
      terms.each do |term|
        tags << term['term'].gsub!('#','')
      end
      if terms.empty?
        terms = {}
      else
        terms = {:ows_meta_tags=>tags}
      end
      #build conditions array
      conditions = {
        :conditions=>{
          'entities.media.0.media_url'=>{'$exists'=>true}, 'entities.media.0.sizes.small.h'=>{:$exists=>true},
          :timestamp=> {'$gte'=>campaign[:start_timestamp],'$lte'=>campaign[:end_timestamp]},
          :block=>{'$exists'=>false}.merge(terms)
        }
      }
    puts conditions.inspect
    #get all matching tweets
    tweets = Tweet.all(conditions)
    puts campaign.name
    puts tweets.size
    t_count = tweets.size
    Campaign.collection.update({:slug=>campaign[:slug]},{'$set'=>{:media_count=>t_count}})
    tweets.each do |t|
      #build CM object

      cmd = CampaignMedia.new
      CampaignMedia.collection.update({:campaign_id=>campaign.id, :media_id=>t.id_str.to_s,:media_type=>'tweet'},{:media_id => t.id_str,
        :media_type => 'tweet',
        :campaign_id => campaign.id,
        :ordering_key => t.timestamp},{:upsert=>true})
      end
    end
  end
  
  
  def save_from_url (url,c)
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
  attr_accessor :dims, :image_size, :score, :sized, :sizes
  def removeIds
    
  end

  def removeRetweets
    
  end
  def dimensions!(pixels)
    pixels = @sized.to_i * pixels
    @image_size = ":small"
    begin
      if (@sizes["thumb"] !=nil)
        @image_size =":small"
      end
    rescue
        @image_size = ""
    end
    r = 1
    h = pixels
    biggest = 1
    begin
    d = @sizes["medium"]
    puts "original size"+d.inspect
    d["w"] = d["w"]/4
    d["h"] = d["h"]/4
    pixels = d["w"] * @sized.to_i

    @sizes.keys.reverse.each do |k|
      if (pixels > @sizes[k]["w"].to_i)
        @image_size = ":"+k
        d = @sizes[k]
        biggest = @sizes[k]["w"]
      end
    end
    pixels = (pixels > @sizes["large"]["w"]) ? @sizes["large"]["w"] : pixels
    h = (d["h"].to_f / d['w'].to_f) * pixels.to_f
    ww = (d["w"]*@sized.to_i).to_f.clip(@sizes["large"]["w"])
    hh = (d["h"]*@sized.to_i).to_f.clip(@sizes["large"]["h"])
    @dims = {:width=>ww, :height=>hh}
  rescue Exception=>ex
    @dims = {:width=>pixels, :height=>pixels}
  end
    true
  end
  
  def sizes?
    begin
      if @sizes["large"] !=nil
        true
      end
    rescue
      false
    end
  end
  
  def not_instagram!(url)
    if url.split("instagram").size > 1
      @image_size = ""
      puts "url" + url
      puts "is instagram"

    else
    puts "url"+  url
 	puts "is not instagram"
    end
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
         query = {:rpp=>100, :page=>"2", :since_id =>self.since_id, :until=>date_until,:include_entities=>true}
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
             #corny method to traverse urls that have been encoded multiple times
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
             elsif ((url["expanded_url"]).split("instagr.am").size > 1) || ((url["expanded_url"]).split("instagram.com").size > 1)
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
           #save all tweets, to mine them later
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

class AggregateMedia
  include MongoMapper::Document
  key :media_url, String
  key :campaign_id, Array
  key :campaign_media_id, Array
  key :score, Integer, :default=>0
end
AggregateMedia.ensure_index(:score)


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
    
    @prev_id=""
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

class Theme
  include MongoMapper::Document
  plugin MongoMapper::Plugins::Sluggable
  sluggable :name
  key :name, String
  key :template_name, String
  key :cover_image, String
end
  
