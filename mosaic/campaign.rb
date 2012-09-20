get '/campaigns/create' do 
  @terms = []
  @campaign = Campaign.new
  @campaign.edit_link =""
  haml 'campaigns/create'.to_sym
end

post '/campaigns/create' do 
  @campaign = Campaign.new
  @campaign.name = params[:name]
  @campaign.page_title = params[:name]
  @campaign.description = params[:description]
  @campaign.start_timestamp = Time.parse(params[:start_date].to_s).to_i
  @campaign.end_timestamp = Time.parse(params[:end_date].to_s).to_i
  @campaign.edit_link = @campaign.build_edit_link
  @campaign.cover_image = params[:cover_image]
  
  puts params[:start_date]
  puts params[:end_date]
  @campaign.save!
  #create terms for the crawler
  @terms = params[:search_terms].split(',')
  @terms.each do |term|
    t = Term.new
    t.term = term.strip!
    t.campaign_id = @campaign.id
    t.since_id = 0
    t.last_checked = Time.now
    t.save
  end
  @terms = Term.all({:campaign_id => @campaign.id})
  redirect '/campaigns/edit/' << @campaign.edit_link
end


get '/campaigns/edit/:edit_link' do
  #get campaign by edit link
  @campaign = Campaign.first({:edit_link =>params[:edit_link]})
  #get related terms
  @terms = Term.all({:campaign_id => @campaign.id})
    #with ajax interface
  #photos to view in frame
    #/mosaic/admin/:edit_link/p/:page
      #show block
      #show block user
  haml 'campaigns/edit'.to_sym
end

post '/campaigns/edit/:edit_link' do
  #get campaign by edit link
  @campaign = Campaign.first({:edit_link =>params[:edit_link]})
  @campaign.page_title = params[:name]
  @campaign.description = params[:description]
  @campaign.cover_image = params[:cover_image]
  @campaign.save!
  puts @campaign.inspect
  #get related terms
  @terms = Term.all({:campaign_id => @campaign.id})
    #with ajax interface
  #photos to view in frame
    #/mosaic/admin/:edit_link/p/:page
      #show block
      #show block user
  redirect '/campaigns/edit/' << @campaign.edit_link
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
        Campaign.collection.update({:slug=>@c.slug},{'$unset'=>{:conditions=>true}})
    end
  end
  haml :about
end

get '/campaigns/build_collection' do
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
      haml :about
end

get '/campaigns/update/:edit_link' do
  @campaign = Campaign.first({:edit_link=>params[:edit_link]})
  #now do a hashtag search
  @campaign.update_media
  redirect '/admin/campaigns/'<< @campaign.edit_link 
end



post '/campaigns/add_term/:edit_link' do
  @campaign = Campaign.first({:edit_link=>params[:edit_link]})
  if(! @campaign.nil?)
    @t = Term.new
    @t.since_id = 1
    @t.last_checked = Time.now
    @t.campaign_id = @campaign.id
    @t.term = params[:term]
    @t.save!
  end
  redirect '/campaigns/edit/' << @campaign.edit_link
end

get '/campaigns/remove_term/:edit_link/:term_id' do
  @campaign = Campaign.first({:edit_link=>params[:edit_link]})
  if(! @campaign.nil?)
    @term = Term.first({:campaign_id =>@campaign.id, :id=>params[:term_id]})
    @term.destroy
  end
  redirect '/campaigns/edit/' << @campaign.edit_link
end

get '/campaigns/purge_term/:edit_link/:term' do
  @campaign = Campaign.first({:edit_link=>params[:edit_link]})
  if(! @campaign.nil?)
  end
  haml 'campaigns/block'.to_sym
end

get '/campaigns/remove_duplicates/:campaign_slug/:edit_link/:id' do
  @c = Campaign.first({:slug=>params[:campaign_slug]})
  if (@c['edit_link']==params[:edit_link])
    @d = CampaignMedia.all({:media_id=>params[:id]})
    x = @d.count-1
    @d[1..x].each do |cm|
      cm.destroy
    end
    haml 'campaigns/block'.to_sym
  end
end

get '/campaigns/block/:campaign_slug/:edit_link/:id' do
  @c = Campaign.first({:slug=>params[:campaign_slug]})
  if (@c['edit_link']==params[:edit_link])
    Tweet.collection.update({:id_str=>params[:id]},{'$set'=>{:block=>true}})
    CampaignMedia.collection.update({:campaign_id=>@c.id, :media_id=>params[:id]},{'$set'=>{:hidden=>true}})
    @t = Tweet.first({:id_str=>params[:id]})
    haml 'campaigns/block'.to_sym
  end
end