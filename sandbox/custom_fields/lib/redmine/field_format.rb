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

    def self.all
      @formats ||= Hash.new(Base.instance)
    end

    def self.available_formats
      all.keys
    end

    def self.find(name)
      all[name.to_s]
    end

    class Base
      include Singleton

      # Set this to true if the format supports multiple values
      class_attribute :multiple_supported
      self.multiple_supported = false

      # Set this to true if the format supports textual search on custom values
      class_attribute :searchable_supported
      self.searchable_supported = false

      def self.add(name)
        Redmine::FieldFormat.add(name, self)
      end

      def cast_single_value(custom_field, value, customized=nil)
        value.to_s
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
    end

    class Numeric < Unbounded
    end

    class IntFormat < Numeric
      add 'int'

      def cast_single_value(custom_field, value, customized=nil)
        value.to_i
      end

      def validate_single_value(custom_field, value, customized=nil)
        errs = super
        errs << ::I18n.t('activerecord.errors.messages.not_a_number') unless value =~ /^[+-]?\d+$/
        errs
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
    end

    class BoolFormat < Base
      add 'bool'

      def cast_single_value(custom_field, value, customized=nil)
        value == '1' ? true : false
      end
    end

    class List < Base
      self.multiple_supported = true
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

      def cast_single_value(custom_field, value, customized=nil)
        target_class.find_by_id(value.to_i) if value.present?
      end

      def target_class
        @target_class ||= self.class.name[/^(.*::)?(.+)Format$/, 2].constantize rescue nil
      end
    end

    class UserFormat < ObjectList
      add 'user'
    end

    class VersionFormat < ObjectList
      add 'version'
    end
  end
end
