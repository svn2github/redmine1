ActionController::Routing::Routes.draw do |map|
  map.connect 'embedded/:id/*path', :controller => 'embedded', :action => 'index'
end
