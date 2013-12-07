# Redmine - project management software
# Copyright (C) 2006-2013  Jean-Philippe Lang
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

require File.expand_path('../../../../../test_helper', __FILE__)
require 'redmine/field_format'

class Redmine::UserFieldFormatTest < ActionView::TestCase
  include ApplicationHelper

  fixtures :projects, :roles, :users, :members, :member_roles

  def test_possible_values_options_should_return_project_members
    field = IssueCustomField.new(:field_format => 'user')
    project = Project.find(1)

    assert_equal ['Dave Lopper', 'John Smith'], field.possible_values_options(project).map(&:first)
  end

  def test_possible_values_options_should_return_project_members_with_selected_role
    field = IssueCustomField.new(:field_format => 'user', :user_role => ["2"])
    project = Project.find(1)

    assert_equal ['Dave Lopper'], field.possible_values_options(project).map(&:first)
  end
end
