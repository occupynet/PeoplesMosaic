#campaign_id is the edit slug - unguessable
get '/terms/:campaign_id' do 
  @terms = Term.all({:order=>:term.asc})
  haml 'terms/index'.to_sym
end

#save a new term
post '/terms/:campaign_id' do 
  Term.collection.update({:term=>params[:term]}, {:term=>params[:term],:last_checked=>Time.now,:is_active=>params[:is_active],:campaign_id=>params[:campaign_id]},{:upsert=>true})
  @terms = Term.all({:order=>:term.asc})
  haml 'terms/index'.to_sym
end

get '/terms/:campaign_id/edit/:id' do
  @term = Term.find(params[:id])
  @selected = {:yes=>'',:no=>''}
  @selected[@term['is_active']]='selected'
  haml 'terms/edit'.to_sym
end