require File.join(File.dirname(__FILE__),'campaign.rb')
#get all of the photos within a grid size of x and y 

class Mosaic 
  attr_accessor :page_size, :campaign, :conditions, :meta_info, :sorting
  def initialize(slug)
    @campaign = Campaign.first(:slug=>slug)
  end
  
  def is_active?
    if @campaign.end_timestamp.to_i > Time.now.to_i
      true
    else
      false
    end
  end
  
  def set_sorting
    if self.is_active? 
      @sorting = 'ordering_key desc'
    else 
      @sorting = 'ordering_key asc'
    end
  end
  
  def grid(skip)
    #get our Campaign object
    #get CampaignMedia that match campaign ID
    @conditions = {
      :limit=>@page_size, :skip=>skip * @page_size,:order=>@sorting,
      :conditions=>{:campaign_id=>@campaign.id, :hidden=>{'$exists'=>false}}
    }
    @meta_info = {:page_title => @campaign['page_title'], :description => @campaign['description']}
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

get '/:campaign_slug' do
  m = Mosaic.new(params[:campaign_slug])
  m.set_sorting
  m.page_size = 50
  @campaign = m.campaign
  @terms = Term.all({:campaign_id=>@campaign.id})
  @active = m.is_active?
  @sorting = m.is_active? ? "newest" : "oldest"
  @squares = m.grid(0)
  @page = 2
  @meta = m.meta_info
  haml 'mosaic/grid'.to_sym  
end

get '/page/?:campaign_slug/:page' do
  @page = params[:page].to_i+1
  m = Mosaic.new(params[:campaign_slug])
  m.set_sorting
  m.page_size = 50
  @campaign = m.campaign
  @squares =m.grid(@page)
  @meta = m.meta_info
  @terms = Term.all({:campaign_id=>@campaign.id})
  haml 'mosaic/grid'.to_sym  
end


get '/admin/campaigns/:edit_link' do
  #get campaign from edit_link
  @campaign = Campaign.first({:edit_link=>params['edit_link']})
  if (@campaign)
    m = Mosaic.new(@campaign['slug'])
    m.set_sorting
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
    m = Mosaic.new(@campaign['slug'])
    m.set_sorting
    m.page_size = 50
    @squares =m.grid(@page)
    @meta = m.meta_info
    haml 'mosaic/admin_grid'.to_sym  
  end
end



