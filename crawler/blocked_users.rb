
get '/users/block/:user_id' do 
  #add user to blocks table
  #flag all existing tweets and crawled tweets to hide
  BlockedUser.collection.update({:user_id=>params[:user_id]},{:user_id=>params[:user_id]},{:upsert=>true})
  #block their tweets, in a better way
  @tweets = Tweet.all({:conditions=>{:user.id=>params[:user_id]}})
  @tweets.each do |tweet|
    tweet["block"] = 1
    Tweet.collection.update({:id_str=>tweet.attrs["id_str"].to_s},tweet.attrs, {:upsert => true})
  end
end

get '/users/block' do 
  @tweet = {:text=>""}
  haml :block
end
get '/block/:id_str' do 
  @tweet = Tweet.first({:conditions=>{:id_str=>params[:id_str]}})
  @tweet['block'] =1
  puts @tweet.inspect
  @tweet.save
  haml :block
end

