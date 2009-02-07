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

require File.dirname(__FILE__) + '/../../../test_helper'

class Redmine::I18nTest < Test::Unit::TestCase
  include Redmine::I18n
  
  def setup
    @hook_module = Redmine::Hook
  end
  
  def test_date_format_default
    today = Date.today
    Setting.date_format = ''    
    assert_equal I18n.l(today), format_date(today)
  end
  
  def test_date_format
    today = Date.today
    Setting.date_format = '%d %m %Y'
    assert_equal today.strftime('%d %m %Y'), format_date(today)
  end
  
  def test_time_format_default
    now = Time.now
    Setting.date_format = ''
    Setting.time_format = ''    
    assert_equal I18n.l(now), format_time(now)
    assert_equal I18n.l(now, :format => :time), format_time(now, false)
  end
  
  def test_time_format
    now = Time.now
    Setting.date_format = '%d %m %Y'
    Setting.time_format = '%H %M'
    assert_equal now.strftime('%d %m %Y %H %M'), format_time(now)
    assert_equal now.strftime('%H %M'), format_time(now, false)
  end
  
  def test_utc_time_format
    now = Time.now.utc
    Setting.date_format = '%d %m %Y'
    Setting.time_format = '%H %M'
    assert_equal Time.now.strftime('%d %m %Y %H %M'), format_time(now)
    assert_equal Time.now.strftime('%H %M'), format_time(now, false)
  end
end
