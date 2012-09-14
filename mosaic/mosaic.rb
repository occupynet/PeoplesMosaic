require File.join(File.dirname(__FILE__),'campaign.rb')
#get all of the photos within a grid size of x and y 

class Mosaic 
  attr_accessor :page_size, :campaign, :conditions, :meta_info
  def grid(skip)
    #get our Campaign object
    if @campaign == nil
      camp = Campaign.first
    else
      camp = Campaign.first(:slug=>@campaign)
    end
    puts "end time"
    puts Time.at(camp.end_timestamp.to_i)
    puts camp.end_timestamp.to_i
    puts "now"
    puts Time.now.to_i
    puts (camp.end_timestamp.to_i > Time.now.to_i)
    sort = 'ordering_key asc'
    if camp.end_timestamp.to_i > Time.now.to_i
      sort = 'ordering_key desc'
    end
    puts sort.inspect
    #get CampaignMedia that match campaign ID
    @conditions = {
      :limit=>@page_size, :skip=>skip * @page_size,:order=>sort,
      :conditions=>{:campaign_id=>camp.id, :hidden=>{'$exists'=>false}}
    }
    @meta_info = {:page_title => camp['page_title'], :description => camp['description']}
   #return all crawled tweets with conditions c
   cm = CampaignMedia.all(@conditions)
   tweets = []
   h = {}
   #uniqe tweets enforced like this, because we can't do a distinct dbcommand in this version of ruby
   #and because some weird mongomapper bugs keep duplicating our CampaignMedia entries
   cm.each do |c|
     if (h[c.media_id.to_s] !=true)
       h[c.media_id.to_s] = true
       tweets << Tweet.first({:id_str=>c.media_id.to_s})
     end
   end
   #cm.each do |c|
  #   tweets << Tweet.first({:id_str=>c.media_id.to_s})
  # end
  tweets
 end
end



get '/about' do 
  haml :about
end

get '/:campaign' do
  m = Mosaic.new
  m.campaign = params[:campaign]
  m.page_size = 50
  @squares = m.grid(0)
  @page = 2
  @campaign = m.campaign
  @meta = m.meta_info
  haml 'mosaic/grid'.to_sym  
end

get '/page/?:campaign/:page' do
  @page = params[:page].to_i+1
  m = Mosaic.new
  m.campaign = params[:campaign]
  m.page_size = 50
  @campaign = m.campaign
  @squares =m.grid(@page)
  @meta = m.meta_info
  haml 'mosaic/grid'.to_sym  
end


get '/admin/campaigns/:edit_link' do
  #get campaign from edit_link
  @campaign = Campaign.first({:edit_link=>params['edit_link']})
  if (@campaign)
    m = Mosaic.new
    m.campaign = @campaign['slug']
    m.page_size = 50
    @squares = m.grid(0)
    @page = 2
    @meta = m.meta_info
  end
  haml 'mosaic/admin_grid'.to_sym  
end

get '/admin/campaigns/page/:edit_link/:page' do
  @campaign = Campaign.first({:edit_link=>params['edit_link']})
  if (@campaign)
    @page = params[:page].to_i+1
    m = Mosaic.new
    m.campaign = params[:campaign]
    m.page_size = 50
    m.campaign = @campaign['slug']
    @squares =m.grid(@page)
    @meta = m.meta_info
    haml 'mosaic/admin_grid'.to_sym  
  end
end



