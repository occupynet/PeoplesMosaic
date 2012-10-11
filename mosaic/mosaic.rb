require File.join(File.dirname(__FILE__),'campaign.rb')
#get all of the photos within a grid size of x and y 

class Mosaic 
  attr_accessor :page_size, :campaign, :conditions, :meta_info, :sorting, :theme
  def initialize(slug)
    @campaign = Campaign.first(:slug=>slug)
    if @campaign[:theme_id]==nil
      @theme = Theme.first({:slug=>"default"})
    else 
      @theme = Theme.first({:id=>@campaign.theme_id})
    end
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
  
  def cloud(skip)
    @conditions = {
      :limit=>@page_size, :skip=>skip * @page_size,:order=>@sorting,
      :conditions=>{:campaign_id=>@campaign.id, :hidden=>{'$exists'=>false}}
    }
    @meta_info = {:page_title => @campaign['page_title'], :description => @campaign['description']}
   cm = AggregateMedia.all(@conditions)
   tweets = []
   h = {}
   cm.each do |c|
     t = Tweet.first({:id_str=>c.media_id.to_s})
     t.score = c.score
     sc = (c.score < 1) ?  0 : Math.log(c.score)
     t.sized =((sc / Math.log(3)) * (8/9)**c.score).ceil+1
     begin
       t.sizes = t["entities"]["media"][0]["sizes"]
     rescue
       t.sizes = Hash.new
       t.sizes["small"] = {"w"=>150, "h"=>150}
     end
     
     t.dimensions!(90)
     begin
      t.not_instagram!(t["entities"]["media"][0]["media_url"].to_s)
      rescue
      end
     tweets << t
   end
   tweets
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
  m.page_size = 60
  @campaign = m.campaign
  @terms = Term.all({:campaign_id=>@campaign.id})
  @active = m.is_active?
  @sorting = m.is_active? ? "newest" : "oldest"
  @squares = m.cloud(0)
  @page = 2
  @meta = m.meta_info
  haml ('mosaic/themes/'+m.theme.template_name).to_sym  
end

get '/page/?:campaign_slug/:page' do
  @page = params[:page].to_i-1
  m = Mosaic.new(params[:campaign_slug])
  m.set_sorting
  m.page_size = 60
  @campaign = m.campaign
  @squares =m.cloud(@page)
  @meta = m.meta_info
  @terms = Term.all({:campaign_id=>@campaign.id})
  haml ('mosaic/themes/'+m.theme.template_name).to_sym  
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
    @page = params[:page].to_i-1
    m = Mosaic.new(@campaign['slug'])
    m.set_sorting
    m.page_size = 50
    @squares =m.grid(@page)
    @meta = m.meta_info
    haml 'mosaic/admin_grid'.to_sym  
  end
end



