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

module Redmine
  module FieldFormat
    def self.add(name, klass)
      all[name.to_s] = klass.instance
    end

    def self.delete(name)
      all.delete(name.to_s)
    end

    def self.all
      @formats ||= Hash.new(Base.instance)
    end

    def self.available_formats
      all.keys
    end

    def self.find(name)
      all[name.to_s]
    end

    # Return an array of custom field formats which can be used in select_tag
    def self.as_select(class_name=nil)
      formats = all.values
      formats.select! do |format|
        format.class.customized_class_names.nil? || format.class.customized_class_names.include?(class_name)
      end
      formats.map {|format| [::I18n.t(format.label), format.name] }.sort_by(&:first)
    end

    class Base
      include Singleton
      include Redmine::I18n

      class_attribute :format_name
      self.format_name = nil

      # Set this to true if the format supports multiple values
      class_attribute :multiple_supported
      self.multiple_supported = false

      # Set this to true if the format supports textual search on custom values
      class_attribute :searchable_supported
      self.searchable_supported = false

      # Restricts the classes that the custom field can be added to
      # Set to nil for no restrictions
      class_attribute :customized_class_names
      self.customized_class_names = nil

      def self.add(name)
        self.format_name = name
        Redmine::FieldFormat.add(name, self)
      end
      private_class_method :add

      def name
        self.class.format_name
      end

      def label
        "label_#{name}"
      end

      def cast_custom_value(custom_value)
        cast_value(custom_value.custom_field, custom_value.value, custom_value.customized)
      end

      def cast_value(custom_field, value, customized=nil)
        if value.blank?
          nil
        elsif value.is_a?(Array)
          value.map do |v|
            cast_single_value(custom_field, v, customized)
          end.sort
        else
          cast_single_value(custom_field, value, customized)
        end
      end

      def cast_single_value(custom_field, value, customized=nil)
        value.to_s
      end

      def target_class
        nil
      end

      def possible_values_options(custom_field, object=nil)
        custom_field.possible_values
      end

      # Returns the validation errors for custom_field
      # Should return an empty array if custom_field is valid
      def validate_custom_field(custom_field)
        []
      end

      # Returns the validation error messages for custom_value
      # Should return an empty array if custom_value is valid
      def validate_custom_value(custom_value)
        errors = Array.wrap(custom_value.value).reject(&:blank?).map do |value|
          validate_single_value(custom_value.custom_field, value, custom_value.customized)
        end
        errors.flatten.uniq
      end

      def validate_single_value(custom_field, value, customized=nil)
        []
      end

      def formatted_custom_value(view, custom_value, html=false)
        formatted_value(view, custom_value.custom_field, custom_value.value, custom_value.customized, html)
      end

      def formatted_value(view, custom_field, value, customized=nil, html=false)
        cast_value(custom_field, value, customized)
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options={})
        view.text_field_tag(tag_name, custom_value.value, options.merge(:id => tag_id))
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
        view.text_field_tag(tag_name, value, options.merge(:id => tag_id)) +
          bulk_clear_tag(view, tag_id, tag_name, custom_field, value)
      end

      def bulk_clear_tag(view, tag_id, tag_name, custom_field, value)
        if custom_field.is_required?
          ''.html_safe
        else
          view.content_tag('label',
            view.check_box_tag(tag_name, '__none__', (value == '__none__'), :id => nil, :data => {:disables => "##{tag_id}"}) + l(:button_clear),
            :class => 'inline'
          )
        end
      end
      protected :bulk_clear_tag

      def query_filter_options(custom_field, query)
        {:type => :string}
      end
    end

    class Unbounded < Base
      def validate_single_value(custom_field, value, customized=nil)
        errs = super
        if value.present?
          unless custom_field.regexp.blank? or value =~ Regexp.new(custom_field.regexp)
            errs << ::I18n.t('activerecord.errors.messages.invalid')
          end
          if custom_field.min_length > 0 and value.length < custom_field.min_length
            errs << ::I18n.t('activerecord.errors.messages.too_short', :count => custom_field.min_length)
          end
          if custom_field.max_length > 0 and value.length > custom_field.max_length
            errs << ::I18n.t('activerecord.errors.messages.too_long', :count => custom_field.max_length)
          end
        end
        errs
      end
    end

    class StringFormat < Unbounded
      add 'string'
      self.searchable_supported = true
    end

    class TextFormat < Unbounded
      add 'text'
      self.searchable_supported = true

      def edit_tag(view, tag_id, tag_name, custom_value, options={})
        view.text_area_tag(tag_name, custom_value.value, options.merge(:id => tag_id, :rows => 3))
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
        view.text_area_tag(tag_name, value, options.merge(:id => tag_id, :rows => 3)) +
          '<br />'.html_safe +
          bulk_clear_tag(view, tag_id, tag_name, custom_field, value)
      end

      def query_filter_options(custom_field, query)
        {:type => :text}
      end
    end

    class Numeric < Unbounded
    end

    class IntFormat < Numeric
      add 'int'

      def label
        "label_integer"
      end

      def cast_single_value(custom_field, value, customized=nil)
        value.to_i
      end

      def validate_single_value(custom_field, value, customized=nil)
        errs = super
        errs << ::I18n.t('activerecord.errors.messages.not_a_number') unless value =~ /^[+-]?\d+$/
        errs
      end

      def query_filter_options(custom_field, query)
        {:type => :integer}
      end
    end

    class FloatFormat < Numeric
      add 'float'

      def cast_single_value(custom_field, value, customized=nil)
        value.to_f
      end

      def validate_single_value(custom_field, value, customized=nil)
        errs = super
        errs << ::I18n.t('activerecord.errors.messages.invalid') unless (Kernel.Float(value) rescue nil)
        errs
      end

      def query_filter_options(custom_field, query)
        {:type => :float}
      end
    end

    class DateFormat < Unbounded
      add 'date'

      def cast_single_value(custom_field, value, customized=nil)
        value.to_date rescue nil
      end

      def validate_single_value(custom_field, value, customized=nil)
        if value =~ /^\d{4}-\d{2}-\d{2}$/ && (value.to_date rescue false)
          []
        else
          [::I18n.t('activerecord.errors.messages.not_a_date')]
        end
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options={})
        view.text_field_tag(tag_name, custom_value.value, options.merge(:id => tag_id, :size => 10)) +
          view.calendar_for(tag_id)
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
        view.text_field_tag(tag_name, value, options.merge(:id => tag_id, :size => 10)) +
          view.calendar_for(tag_id) +
          bulk_clear_tag(view, tag_id, tag_name, custom_field, value)
      end

      def query_filter_options(custom_field, query)
        {:type => :date}
      end
    end

    class BoolFormat < Base
      add 'bool'

      def label
        "label_boolean"
      end

      def cast_single_value(custom_field, value, customized=nil)
        value == '1' ? true : false
      end

      def possible_values_options(custom_field, object=nil)
        [[::I18n.t(:general_text_Yes), '1'], [::I18n.t(:general_text_No), '0']]
      end

      def edit_tag(view, tag_id, tag_name, custom_value, options={})
        view.hidden_field_tag(tag_name, '0') +
          view.check_box_tag(tag_name, '1', custom_value.true?, options.merge(:id => tag_id))
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
        view.select_tag(tag_name,
          view.options_for_select([
            [l(:label_no_change_option), ''],
            [l(:general_text_Yes), '1'],
            [l(:general_text_No), '0']], value),
          options.merge(:id => tag_id))
      end

      def query_filter_options(custom_field, query)
        {:type => :list, :values => possible_values_options(custom_field)}
      end
    end

    class List < Base
      self.multiple_supported = true

      def edit_tag(view, tag_id, tag_name, custom_value, options={})
        blank_option = ''.html_safe
        unless custom_value.custom_field.multiple?
          if custom_value.custom_field.is_required?
            unless custom_value.custom_field.default_value.present?
              blank_option = view.content_tag('option', "--- #{l(:actionview_instancetag_blank_option)} ---", :value => '')
            end
          else
            blank_option = view.content_tag('option')
          end
        end
        options_tags = blank_option + view.options_for_select(possible_values_options(custom_value.custom_field, custom_value.customized), custom_value.value)
        s = view.select_tag(tag_name, options_tags, options.merge(:id => tag_id, :multiple => custom_value.custom_field.multiple?))
        if custom_value.custom_field.multiple?
          s << view.hidden_field_tag(tag_name, '')
        end
        s
      end

      def bulk_edit_tag(view, tag_id, tag_name, custom_field, objects, value, options={})
        opts = []
        opts << [l(:label_no_change_option), ''] unless custom_field.multiple?
        opts << [l(:label_none), '__none__'] unless custom_field.is_required?
        opts += possible_values_options(custom_field, objects)
        view.select_tag(tag_name, view.options_for_select(opts, value), options.merge(:multiple => custom_field.multiple?))
      end

      def query_filter_options(custom_field, query)
        {:type => :list_optional, :values => possible_values_options(custom_field, query.project)}
      end
    end

    class ListFormat < List
      add 'list'
      self.searchable_supported = true

      def validate_custom_field(custom_field)
        errors = []
        errors << [:possible_values, :blank] if custom_field.possible_values.blank?
        errors << [:possible_values, :invalid] unless custom_field.possible_values.is_a? Array
        errors
      end

      def validate_single_value(custom_field, value, customized=nil)
        if custom_field.possible_values.include?(value)
          []
        else
          [::I18n.t('activerecord.errors.messages.inclusion')]
        end
      end
    end

    class ObjectList < List
      self.customized_class_names = %w(Issue TimeEntry Version Project)

      def cast_single_value(custom_field, value, customized=nil)
        target_class.find_by_id(value.to_i) if value.present?
      end

      def target_class
        @target_class ||= self.class.name[/^(.*::)?(.+)Format$/, 2].constantize rescue nil
      end
    end

    class UserFormat < ObjectList
      add 'user'

      def possible_values_options(custom_field, object=nil)
        if object.is_a?(Array)
          projects = object.map {|o| o.respond_to?(:project) ? o.project : nil}.compact.uniq
          projects.map {|project| possible_values_options(custom_field, project)}.reduce(:&) || []
        elsif object.respond_to?(:project) && object.project
          object.project.users.sort.collect {|u| [u.to_s, u.id.to_s]}
        else
          []
        end
      end
    end

    class VersionFormat < ObjectList
      add 'version'

      def possible_values_options(custom_field, object=nil)
        if object.is_a?(Array)
          projects = object.map {|o| o.respond_to?(:project) ? o.project : nil}.compact.uniq
          projects.map {|project| possible_values_options(custom_field, project)}.reduce(:&) || []
        elsif object.respond_to?(:project) && object.project
          object.project.shared_versions.sort.collect {|u| [u.to_s, u.id.to_s]}
        else
          []
        end
      end
    end
  end
end
