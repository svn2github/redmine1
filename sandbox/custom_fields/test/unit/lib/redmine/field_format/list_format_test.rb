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

class Redmine::ListFieldFormatTest < ActionView::TestCase
  include ApplicationHelper

  def test_possible_existing_value_should_be_valid
    field = GroupCustomField.create!(:name => 'List', :field_format => 'list', :possible_values => ['Foo', 'Bar'])
    group = Group.new(:name => 'Group')
    group.custom_field_values = {field.id => 'Baz'}
    assert group.save(:validate => false)

    group = Group.order('id DESC').first
    assert_equal ['Foo', 'Bar', 'Baz'], field.possible_custom_value_options(group.custom_value_for(field))
    assert group.valid?
  end
end
