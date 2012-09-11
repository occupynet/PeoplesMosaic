require File.join(File.dirname(__FILE__),'blocked_users.rb')
require File.join(File.dirname(__FILE__),'expand_url.rb')
require File.join(File.dirname(__FILE__),'blocked_users.rb')
#crawl a tweet search term
# 
# 
# 
# 
# 
#lambda for each service to scrape or api
#Tweet.first({:conditions=>{["entities.urls.0.expanded_url"]=>{'$exists'=>true},["entities.urls.0.expanded_url"]=>/#{service}/}})

get '/crawl' do 
  #fitler out retweets
    @terms = Term.all({:conditions=>{:is_active=>'yes'},:order=>:last_checked.desc})
    @blocked = BlockedUser.all
    @block = {}
    sleep 1
    @blocked.each do |block|
      @block[block["user_id"]] = block["user_id"]
    end
    @time = ['2012-05-02','2012-05-03','2012-05-04']
  
    @terms.each do |term|
      @time.each do |date_until|
        puts term.inspect
        #find one term to get max id
        max = Tweet.all({:conditions=>{:timestamp=>{:$lte=>Time.parse(date_until).to_i},:text=>Regexp.new(term.term)},:limit=>1, :order=>:timestamp.asc})
        puts max.inspect
        if (max[0] !=nil )
          max_id = {:max_id=>max[0].id_str}        
        else
          max_id = {}
        end
        puts max_id.inspect
        puts date_until
        15.times do |p|
          begin 
          tweets = Twitter.search(term.term.to_s + " -rt",{:rpp=>100, :page => (p+1).to_i,:since_id =>196982181401341952, :until=>date_until,:include_entities=>1}.merge(max_id))
          rescue Twitter::Error::BadGateway
          rescue Twitter::Error::Forbidden 
          rescue NoMethodError
            puts "bad gateway"
            sleep 120
            tweets = Twitter.search(term.term.to_s + " -rt",{:rpp=>100, :page => (p+1).to_i,:since_id =>196982181401341952, :until=>date_until,:include_entities=>1}.merge(max_id))          end
          begin 
            puts tweets.size
          rescue NoMethodError
            tweets = []
          end
          tweets.each do | a_tweet |
            begin 
              a_tweet.attrs["timestamp"] = Time.parse(a_tweet.attrs["created_at"]).to_i
            rescue NoMethodError
              a_tweet.attrs["timestamp"] = 1
            end
      
            #extract vids for embed code
            if a_tweet.attrs["entities"]
              if a_tweet.attrs["entities"]["urls"] !=nil
              a_tweet.attrs["entities"]["urls"].each do |url|
                begin 
                  url["expanded_url"].expand_urls!
                rescue NoMethodError
                  url["expanded_url"] = ""
                end
                if url["expanded_url"].split("youtube.com").size >1 || url["expanded_url"].split("youtu.be").size > 1
                  client = YouTubeIt::Client.new(:dev_key => @devkey)
                  begin 
                    vid = client.video_by(url["expanded_url"])
                    a_tweet.attrs["video_embed"] = vid.embed_html
                  rescue OpenURI::HTTPError => e
                  
                  end
                elsif (url["expanded_url"].split("vimeo.com").size > 1)
                  video_id = url["expanded_url"].split("/").last
                  vid = Vimeo::Simple::Video.info(video_id)
                  a_tweet.attrs["video_embed"] =  '<iframe src="http://player.vimeo.com/video/#{vid.id}" width="500" height="313" frameborder="0" webkitAllowFullScreen mozallowfullscreen allowFullScreen></iframe>'
            
                elsif (url["expanded_url"].split("ht.ly").size > 1)
                  a_tweet.attrs["block"] =1
            
                elsif (url["expanded_url"]).split("instagr.am").size > 1
                  begin OpenURI::HTTPError
                  #add the media link
                    html = ""
                    open(url["expanded_url"]) {|f|
                      f.each_line {|line| html << line}
                    }
                   @html = Hpricot(html)
                   #a_tweet.attrs["entities.media.0.media_url"] =(@html/"img.photo")[0][:src]
                   a_tweet.attrs["entities"]["media"] = [:media_url=>(@html/"img.photo")[0][:src] , :expanded_url=>  (@html/"img.photo")[0][:src],:size=>{:small=>{:h=>320}}]
                  rescue 
                  end
                end
                  #expanded url for twitpic
                  #http://instagr.am/
                  #yfrog
                  #via.me
                  #lockerz
              end
            end
            end


            if @block[a_tweet.attrs["from_user_id"].to_s] !=nil
              a_tweet.attrs["block"] = 1
            end
            begin 

           a_tweet.attrs['id'] = nil  
           a_tweet. 
           Tweet.collection.update({:id_str=>a_tweet.attrs["id_str"].to_s},a_tweet.attrs, {:upsert => true})
          rescue  
          end
          end
          sleep 2
        end
       #save check time for this term
       
        sleep 30
      end
    end
  haml :crawl
end

get "/crawl/tweets/:page/?:media:?" do
  if params[:page]==nil
    page = 0
  else
    page = params[:page].to_i 
  end
  
  if params[:media] !=nil
  # 0 = everything
  # 1 = videos, no photos
  # 2 = photos, no videos
  # 3 = photos and videos
  filter_media = [{:video_embed=>{'$exists'=>true}},{:image_url=>{'$exists'=>true}}]
  
    if params[:media]==1
      filter_media = [{:video_embed=>{'$exists'=>true}}]
    else 
      filter_media = [{}]
    end
  end
  @media = params[:media]
  if page > 0 
    @prev = page -1
  end
  @next = page + 1
  #not blocked users
  @tweets = Tweet.all({:conditions=>{:block=>{'$exists'=>false}},:limit=>25, :skip=>25*page,:order=>:timestamp.asc}.merge(filter_media[0]))
  haml :tweets
end
