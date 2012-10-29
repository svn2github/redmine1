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

require File.expand_path('../../test_helper', __FILE__)

class AttachmentsTest < ActionController::IntegrationTest
  fixtures :projects, :enabled_modules,
           :users, :roles, :members, :member_roles,
           :trackers, :projects_trackers,
           :issue_statuses, :enumerations

  def test_upload_as_js_and_attach_to_an_issue
    log_user('jsmith', 'jsmith')

    assert_difference 'Attachment.count' do
      post '/uploads.js?attachment_id=1&filename=myupload.txt', 'File content', {"CONTENT_TYPE" => 'application/octet-stream'}
      assert_response :success
      assert_equal 'text/javascript', response.content_type
    end

    token = response.body.match(/\.val\('(\d+\.[0-9a-f]+)'\)/)[1]
    assert_not_nil token, "No upload token found in response:\n#{response.body}"

    assert_difference 'Issue.count' do
      post '/projects/ecookbook/issues', {
          :issue => {:tracker_id => 1, :subject => 'Issue with upload'},
          :attachments => {'1' => {:filename => 'myupload.txt', :description => 'My uploaded file', :token => token}}
        }
      assert_response 302
    end

    issue = Issue.order('id DESC').first
    assert_equal 'Issue with upload', issue.subject
    assert_equal 1, issue.attachments.count

    attachment = issue.attachments.first
    assert_equal 'myupload.txt', attachment.filename
    assert_equal 'My uploaded file', attachment.description
    assert_equal 'File content'.length, attachment.filesize
  end

  def test_upload_as_js_and_destroy
    log_user('jsmith', 'jsmith')

    assert_difference 'Attachment.count' do
      post '/uploads.js?attachment_id=1&filename=myupload.txt', 'File content', {"CONTENT_TYPE" => 'application/octet-stream'}
      assert_response :success
      assert_equal 'text/javascript', response.content_type
    end

    attachment = Attachment.order('id DESC').first
    attachment_path = "/attachments/#{attachment.id}.js?attachment_id=1"
    assert_include "href: '#{attachment_path}'", response.body, "Path to attachment: #{attachment_path} not found in response:\n#{response.body}"

    assert_difference 'Attachment.count', -1 do
      delete attachment_path
      assert_response :success
    end

    assert_include "$('#attachments_1').remove();", response.body
  end
end
