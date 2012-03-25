require File.expand_path('../../../test_helper', __FILE__)

class RoutingSimpleCiTest < ActionController::IntegrationTest
  def test_simple_ci
    assert_routing(
         { :method => 'get', :path => "/projects/123/simple_ci/show" },
         { :controller => 'simple_ci', :action => 'show', :id => '123' }
      )
    end
 end
