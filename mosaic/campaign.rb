get '/campaigns/create' do 
  @terms = []
  @campaign = Campaign.new
  @campaign.edit_link =""
  @themes = Theme.all
  haml 'campaigns/create'.to_sym
end

post '/campaigns/create' do 
  @campaign = Campaign.new
  @campaign.name = params[:name]
  @campaign.page_title = params[:name]
  @campaign.description = params[:description]
  @campaign.start_timestamp = Time.parse(params[:start_date].to_s).to_i
  @campaign.end_timestamp = Time.parse(params[:end_date].to_s).to_i
  @campaign.cover_image = params[:cover_image]
  @campaign.theme_id = params[:theme_id]
  @campaign.edit_link = @campaign.build_edit_link
  puts params[:start_date]
  puts params[:end_date]
  #first save to build the slug
  #now build the edit link with the slug and save again
  @campaign.save!
  #create terms for the crawler
  @terms = params[:search_terms].split(',')
  @terms.each do |term|
    t = Term.new
    term.strip!
    t.term = term
    t.campaign_id = @campaign.id
    t.since_id = 0
    t.last_checked = Time.now
    t.save
  end
  @terms = Term.all({:campaign_id => @campaign.id})
  redirect '/campaigns/edit/'<<@campaign.slug<<'/'<< @campaign.edit_link
end


get '/campaigns/edit/:slug/:edit_link' do
  @campaign = Campaign.first({:edit_link =>params[:edit_link]})
  @terms = Term.all({:campaign_id => @campaign.id})
  @theme = Theme.first({:id=>@campaign.theme_id})
  @themes = Theme.all
  haml 'campaigns/edit'.to_sym
end

post '/campaigns/edit/:slug/:edit_link' do
  #get campaign by edit link
  @campaign = Campaign.first({:edit_link =>params[:edit_link]})
  @campaign.page_title = params[:name]
  @campaign.description = params[:description]
  @campaign.cover_image = params[:cover_image]
  @campaign.front_page = params[:front_page]
  @campaign.theme_id = params[:theme_id]
  @campaign.save!
  puts @campaign.inspect
  #get related terms
  redirect '/campaigns/edit/'<<@campaign.slug<<'/'<< @campaign.edit_link
end

get '/campaigns/update/:edit_link' do
  @campaign = Campaign.first({:edit_link=>params[:edit_link]})
  #now do a hashtag search
  @campaign.update_media
  redirect '/admin/campaigns/'<< @campaign.edit_link 
end

post '/campaigns/save_url/:edit_link/:url' do

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
    AggregateMedia.collection.update({:campaign_media_id=>params[:id]},{'$set'=>{:hidden=>true}})
    @t = Tweet.first({:id_str=>params[:id]})
    haml 'campaigns/block'.to_sym
  end
end