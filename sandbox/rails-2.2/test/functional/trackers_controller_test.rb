# Redmine - project management software
# Copyright (C) 2006-2009  Jean-Philippe Lang
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

require File.dirname(__FILE__) + '/../test_helper'
require 'trackers_controller'

# Re-raise errors caught by the controller.
class TrackersController; def rescue_action(e) raise e end; end

class TrackersControllerTest < Test::Unit::TestCase
  fixtures :trackers, :projects, :projects_trackers, :users
  
  def setup
    @controller = TrackersController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1 # admin
  end
  
  def test_get_edit
    Tracker.find(1).project_ids = [1, 3]
    
    get :edit, :id => 1
    assert_response :success
    assert_template 'edit'
    
    assert_tag :input, :attributes => { :name => 'tracker[project_ids][]',
                                        :value => '1',
                                        :checked => 'checked' }
    
    assert_tag :input, :attributes => { :name => 'tracker[project_ids][]',
                                        :value => '2',
                                        :checked => nil }
                                        
    assert_tag :input, :attributes => { :name => 'tracker[project_ids][]',
                                        :value => '',
                                        :type => 'hidden'}
  end

  def test_post_edit
    post :edit, :id => 1, :tracker => { :name => 'Renamed',
                                        :project_ids => ['1', '2', ''] }
    assert_redirected_to '/trackers/list'
    assert_equal [1, 2], Tracker.find(1).project_ids.sort
  end

  def test_post_edit_without_projects
    post :edit, :id => 1, :tracker => { :name => 'Renamed',
                                        :project_ids => [''] }
    assert_redirected_to '/trackers/list'
    assert Tracker.find(1).project_ids.empty?
  end
end
