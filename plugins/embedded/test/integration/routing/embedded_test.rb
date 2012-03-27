require File.expand_path('../../../test_helper', __FILE__)

class RoutingEmbeddedTest < ActionController::IntegrationTest
  def test_embedded
    assert_routing(
         { :method => 'get', :path => "/embedded/321" },
         { :controller => 'embedded', :action => 'index', :id => '321',
           :path => [] }
      )
    assert_routing(
         { :method => 'get', :path => "/embedded/321/index.html" },
         { :controller => 'embedded', :action => 'index', :id => '321',
           :path => ['index.html'] }
      )
    assert_routing(
         { :method => 'get', :path => "/embedded/321/dir00/index.html" },
         { :controller => 'embedded', :action => 'index', :id => '321',
           :path => ['dir00', 'index.html'] }
      )
    end
 end
