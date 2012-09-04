#get all of the photos within a grid size of x and y 
class Mosaic 
  attr_accessor :page_size, :campaign, :conditions, :meta_info
  def grid(skip)
    if @campaign == nil
      camp = Campaign.first
    else
      camp = Campaign.first(:slug=>@campaign)
    end
    #get our Campaign object
    puts camp.inspect 
    @conditions = {:limit=>@page_size, :skip=>skip * @page_size,:order=>:timestamp.asc, :conditions=>{'entities.media.0.media_url'=>{:$exists=>true}, 'entities.media.0.sizes.small.h'=>{:$exists=>true}, 'entities.urls.0.expanded_url'=>{'$not'=>/yfrog/}, :timestamp=>{'$gte'=>camp['conditions']['start_time'].to_i,'$lte'=>camp['conditions']['end_time'].to_i},:block=>{:$exists=>false}}}
    @meta_info = {:page_title => camp['page_title'], :description => camp['description']}
   #return all crawled tweets with conditions c
   puts @conditions.inspect
   Tweet.all(@conditions)
  end
end



get '/about' do 
  haml :about
end


#temporarily disable yfrog - images need correct dimensions
get '/+?:campaign?' do
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
