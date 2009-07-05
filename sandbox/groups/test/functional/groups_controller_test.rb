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
require 'groups_controller'

# Re-raise errors caught by the controller.
class GroupsController; def rescue_action(e) raise e end; end

class GroupsControllerTest < Test::Unit::TestCase
  fixtures :projects, :users
  
  def setup
    @controller = GroupsController.new
    @request    = ActionController::TestRequest.new
    @response   = ActionController::TestResponse.new
    User.current = nil
    @request.session[:user_id] = 1
  end
  
  def test_index
    get :index
    assert_response :success
    assert_template 'index'
  end
  
  def test_show
    get :show, :id => 10
    assert_response :success
    assert_template 'show'
  end
  
  def test_new
    get :new
    assert_response :success
    assert_template 'new'
  end
  
  def test_create
    assert_difference 'Group.count' do
      post :create, :group => {:lastname => 'New group'}
    end
    assert_redirected_to 'groups'
  end
  
  def test_edit
    get :edit, :id => 10
    assert_response :success
    assert_template 'edit'
  end
  
  def test_update
    post :update, :id => 10
    assert_redirected_to 'groups'
  end
  
  def test_destroy
    assert_difference 'Group.count', -1 do
      post :destroy, :id => 10
    end
    assert_redirected_to 'groups'
  end
end
