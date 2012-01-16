# encoding: utf-8
#
# Redmine - project management software
# Copyright (C) 2006-2011  Jean-Philippe Lang
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

module QueriesHelper

  def operators_for_select(filter_type)
    Query.operators_by_filter_type[filter_type].collect {|o| [l(Query.operators[o]), o]}
  end

  def column_header(column)
    column.sortable ? sort_header_tag(column.name.to_s, :caption => column.caption,
                                                        :default_order => column.default_order) :
                      content_tag('th', h(column.caption))
  end

  def column_content(column, issue)
    value = column.value(issue)

    case value.class.name
    when 'String'
      if column.name == :subject
        link_to(h(value), :controller => 'issues', :action => 'show', :id => issue)
      else
        h(value)
      end
    when 'Time'
      format_time(value)
    when 'Date'
      format_date(value)
    when 'Fixnum', 'Float'
      if column.name == :done_ratio
        progress_bar(value, :width => '80px')
      elsif  column.name == :spent_hours
        sprintf "%.2f", value
      else
        h(value.to_s)
      end
    when 'User'
      link_to_user value
    when 'Project'
      link_to_project value
    when 'Version'
      link_to(h(value), :controller => 'versions', :action => 'show', :id => value)
    when 'TrueClass'
      l(:general_text_Yes)
    when 'FalseClass'
      l(:general_text_No)
    when 'Issue'
      link_to_issue(value, :subject => false)
    else
      h(value)
    end
  end

  # Retrieve query from session or build a new query
  def retrieve_query
    if !params[:query_id].blank?
      cond = "project_id IS NULL"
      cond << " OR project_id = #{@project.id}" if @project
      @query = Query.find(params[:query_id], :conditions => cond)
      raise ::Unauthorized unless @query.visible?
      @query.project = @project
      session[:query] = {:id => @query.id, :project_id => @query.project_id}
      sort_clear
    elsif api_request? || params[:set_filter] || session[:query].nil? || session[:query][:project_id] != (@project ? @project.id : nil)
      # Give it a name, required to be valid
      @query = Query.new(:name => "_")
      @query.project = @project
      build_query_from_params
      session[:query] = {:project_id => @query.project_id, :filters => @query.filters, :group_by => @query.group_by, :column_names => @query.column_names}
    else
      # retrieve from session
      @query = Query.find_by_id(session[:query][:id]) if session[:query][:id]
      @query ||= Query.new(:name => "_", :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names])
      @query.project = @project
    end
  end

  def retrieve_query_from_session
    if session[:query]
      if session[:query][:id]
        @query = Query.find_by_id(session[:query][:id])
        return unless @query
      else
        @query = Query.new(:name => "_", :filters => session[:query][:filters], :group_by => session[:query][:group_by], :column_names => session[:query][:column_names])
      end
      if session[:query].has_key?(:project_id)
        @query.project_id = session[:query][:project_id]
      else
        @query.project = @project
      end
      @query
    end
  end

  def build_query_from_params
    if params[:fields] || params[:f]
      @query.filters = {}
      @query.add_filters(params[:fields] || params[:f], params[:operators] || params[:op], params[:values] || params[:v])
    else
      @query.available_filters.keys.each do |field|
        @query.add_short_filter(field, params[field]) if params[field]
      end
    end
    @query.group_by = params[:group_by] || (params[:query] && params[:query][:group_by])
    @query.column_names = params[:c] || (params[:query] && params[:query][:column_names])
  end
end
