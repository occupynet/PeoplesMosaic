get '/campaigns/create' do 
  haml 'campaigns/edit'.to_sym
end

post '/campaigns/create' do 
  @campaign = Campaign.new
  @campaign.name = params[:name]
  @campaign.description = params[:description]
  @campaign.start_timestamp = Time.parse(params[:start_date].to_s).to_i
  @campaign.end_timestamp = Time.parse(params[:end_date].to_s).to_i
  @campaign.edit_link = (0...31).map{65.+(rand(52)).chr}.join
  puts params[:start_date]
  puts params[:end_date]
  @campaign.save
  haml 'campaigns/edit'.to_sym
end

get '/campaigns/reformat' do 
  @campaigns = Campaign.all
  @campaigns.each do |c|
    @c = Campaign.first(:id=>c.id)
    if @c.conditions != nil
      puts "campaign:"
      puts @c.name
      puts @c.conditions.inspect
      puts @c.conditions['start_time']
      st = c.conditions['start_time'].to_i
      et = c.conditions['end_time'].to_i
      @c.set(:edit_link => c.build_edit_link)
      puts @c.inspect
      @c.save
        
        Campaign.collection.update({:slug=>@c.slug},{'$set'=>{:fartle=>'foo', :start_timestamp=>st,:end_timestamp=>et}})
        Campaign.collection.update({:slug=>@c.slug},{'$unset'=>{:conditions=>true}})
    end
  end
  haml :about
end

get '/campaigns/build_collection' do
    #get each campaign
    @campaigns = Campaign.all
    @campaigns.each do |campaign|
      #build conditions array
      conditions = {
        :conditions=>{
          'entities.media.0.media_url'=>{:$exists=>true}, 'entities.media.0.sizes.small.h'=>{:$exists=>true},
          'entities.urls.0.expanded_url'=>{'$not'=>/yfrog/},
          :timestamp=> {'$gte'=>campaign[:start_timestamp],'$lte'=>campaign[:end_timestamp]},
          :block=>{'$exists'=>false}          
        }
      }
    #get all matching tweets
    tweets = Tweet.all(conditions)
    t_count = tweets.size
    Campaign.collection.update({:slug=>campaign[:slug]},{'$set'=>{:media_count=>t_count}})
    tweets.each do |t|
      #build CM object
      puts campaign.name
      puts t.id_str
      cm = {
        :media_id => t.id_str,
        :media_type =>'tweet',
        :campaign_id => campaign.id
      }
      cmd = CampaignMedia.new
      cmd.media_id = t.id
      cmd.media_type = 'tweet'
      cmd.campaign_id = campaign.id
      cmd.ordering_key = t.timestamp
      cmd.set(cm)
      cmd.save!
    end
  end
      #CampaignMedia.collection.update({:media_id=>t.id_str,:campaign_id=>campaign.id},cm,)
      haml :about
end


get '/campaigns/edit/:edit_id' do
  #get the campaign by edit id
  #show the form
  
end

post '/campaigns/edit/:edit_id' do
  #get stuff out of the form
  #save it

end


