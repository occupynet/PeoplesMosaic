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
    #get CampaignMedia that match campaign ID
    @conditions = {
      :limit=>@page_size, :skip=>skip * @page_size,:order=>:ordering_key.asc,
      :conditions=>{:campaign_id=>camp.id}
    }
    @meta_info = {:page_title => camp['page_title'], :description => camp['description']}
   #return all crawled tweets with conditions c
   cm = CampaignMedia.all(@conditions)
   puts cm.inspect
   tweets = []
   cm.each do |c|
     tweets << Tweet.first({:id=>c.media_id})
   end
   puts tweets.inspect
   tweets.reject!{|x|x==nil}
 end
end



get '/about' do 
  haml :about
end


#temporarily disable yfrog - images need correct dimensions
get '/:campaign' do
  m = Mosaic.new
  m.campaign = params[:campaign]
  m.page_size = 30
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
  m.page_size = 30
  @campaign = m.campaign
  @squares =m.grid(@page)
  @meta = m.meta_info
  haml 'mosaic/grid'.to_sym  
end
