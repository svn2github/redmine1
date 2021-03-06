# redMine - project management software
# Copyright (C) 2006  Jean-Philippe Lang
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

class IssueStatus < ActiveRecord::Base
  before_destroy :check_integrity  
  has_many :workflows, :foreign_key => "old_status_id"

  validates_presence_of :name
  validates_uniqueness_of :name
  validates_format_of :name, :with => /^[\w\s\'\-]*$/i
  validates_length_of :html_color, :is => 6
  validates_format_of :html_color, :with => /^[a-f0-9]*$/i

  def before_save
    IssueStatus.update_all "is_default=false" if self.is_default?
  end  
  
  # Returns the default status for new issues
  def self.default
    find(:first, :conditions =>["is_default=?", true])
  end

  # Returns an array of all statuses the given role can switch to
  def new_statuses_allowed_to(role, tracker)
    statuses = []
    for workflow in self.workflows
      statuses << workflow.new_status if workflow.role_id == role.id and workflow.tracker_id == tracker.id
    end unless role.nil? or tracker.nil?
    statuses
  end
  
private
  def check_integrity
    raise "Can't delete status" if Issue.find(:first, :conditions => ["status_id=?", self.id]) or IssueHistory.find(:first, :conditions => ["status_id=?", self.id])
  end
end
