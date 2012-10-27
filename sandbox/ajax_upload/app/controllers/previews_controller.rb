# Redmine - project management software
# Copyright (C) 2006-2012  Jean-Philippe Lang
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

class PreviewsController < ApplicationController
  before_filter :find_project, :find_attachments

  def issue
    @issue = @project.issues.find_by_id(params[:id]) unless params[:id].blank?
    if @issue
      @description = params[:issue] && params[:issue][:description]
      if @description && @description.gsub(/(\r?\n|\n\r?)/, "\n") == @issue.description.to_s.gsub(/(\r?\n|\n\r?)/, "\n")
        @description = nil
      end
      @notes = params[:notes]
    else
      @description = (params[:issue] ? params[:issue][:description] : nil)
    end
    render :layout => false
  end

  def news
    if params[:id].present? && news = News.visible.find_by_id(params[:id])
      @previewed = news
    end
    @text = (params[:news] ? params[:news][:description] : nil)
    render :partial => 'common/preview'
  end

  private

  def find_attachments
  	if (attachments = params[:attachments]).present?
      @attachments = attachments.values.collect { |attachment| Attachment.find_by_token( attachment[:token] )  }
  	end
  end

  def find_project
    project_id = (params[:issue] && params[:issue][:project_id]) || params[:project_id]
    @project = Project.find(project_id)
  rescue ActiveRecord::RecordNotFound
    render_404
  end

end
