ActionController::Routing::Routes.draw do |map|
  map.connect 'projects/:id/simple_ci/show',
              :controller => 'simple_ci',
              :action => 'show'
end
