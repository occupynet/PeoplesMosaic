#define a campaign
#one document
#tags / terms (mapped to terms collection)
  #an internal associative array - term has active / schedule
  
#start time
#end time 
  #for crawl and display
  
#sources - flickr, twitter, instagram etc 
  #to know what api's / modules need to be cralwed
  #vimeo  / youtube for videos
  
  #maybe some stuff about layout of the mosaic page
  

#with edit link, get the campaign page
get '/campaigns/:id/edit' do
  @campaign = Campaign.find(params[:ids])
end

post '/campaigns/:id/edit' do
  #save the edited campaign data
end



#display the save tweet form
get '/campaigns/:id/save' do
  haml :save
end

#fetch one tweet from a twitter url, get the json, save as json
post '/campaigns/:id/save' do
  #parse the id string out of the url
  #fetch the tweet and save it to mongo cache
  #is it twitter? (is twitter.com in the url?)
  #save some meta data 
  #client ip, originating site, meta tags, cache timestamp, processed timestamp
  if (params[:url].split("twitter.com").size >1)
    #ugly split
    id = params[:url].split("twitter.com")[1].split("/")[4]
    a_tweet = Twitter.status(id).attrs
    Tweet.collection.update({:id_str=>a_tweet["id_str"].to_s},a_tweet, {:upsert => true})
    #now view the tweet
    @tweet = a_tweet["text"]
  else
    #if not, parse what we can with hpricot and just save the whole page
    html = ""
    open(params[:url]) {|f|
      f.each_line {|line| html << line}
    }
    @html = Hpricot(html)
    title = (@html/"title")[0].inner_html
    Tweet.collection.update({:url=>params[:url]}, {:html=>html, :url=>params[:url],:title=>title}, {:upsert => true}) 
    @tweet = title
  end
  haml :save
end

  

  