# Copyright (c) 2005-2006 David Barri

require 'gloc'

module ActionController #:nodoc:
  class Base #:nodoc:
    include GLoc
  end
  module Filters #:nodoc:
    module ClassMethods

      # This filter attempts to auto-detect the clients desired language.
      # It first checks the params, then a cookie and then the HTTP_ACCEPT_LANGUAGE
      # request header. If a language is found to match or be similar to a currently
      # valid language, then it sets the current_language of the controller.
      # 
      #   class ExampleController < ApplicationController
      #     set_language :en
      #     autodetect_language_filter :except => 'monkey', :on_no_lang => :lang_not_autodetected_callback
      #     autodetect_language_filter :only => 'monkey', :check_cookie => 'monkey_lang', :check_accept_header => false
      #     ...
      #     def lang_not_autodetected_callback
      #       redirect_to somewhere
      #     end
      #   end
      # 
      # The <tt>args</tt> for this filter are exactly the same the arguments of
      # <tt>before_filter</tt> with the following exceptions:
      # * <tt>:check_params</tt> -- If false, then params will not be checked for a language.
      #   If a String, then this will value will be used as the name of the param.
      # * <tt>:check_cookie</tt> -- If false, then the cookie will not be checked for a language.
      #   If a String, then this will value will be used as the name of the cookie.
      # * <tt>:check_accept_header</tt> -- If false, then HTTP_ACCEPT_LANGUAGE will not be checked for a language.
      # * <tt>:on_set_lang</tt> -- You can specify the name of a callback function to be called when the language
      #   is successfully detected and set. The param must be a Symbol or a String which is the name of the function.
      #   The callback function must accept one argument (the language) and must be instance level.
      # * <tt>:on_no_lang</tt> -- You can specify the name of a callback function to be called when the language
      #   couldn't be detected automatically. The param must be a Symbol or a String which is the name of the function.
      #   The callback function must be instance level.
      #   
      # You override the default names of the param or cookie by calling <tt>GLoc.set_config :default_param_name => 'new_param_name'</tt>
      # and <tt>GLoc.set_config :default_cookie_name => 'new_cookie_name'</tt>.
      def autodetect_language_filter(*args)
        options= args.last.is_a?(Hash) ? args.last : {}
        x= 'Proc.new { |c| l= nil;'
        # :check_params
        unless (v= options.delete(:check_params)) == false
          name= v ? ":#{v}" : 'GLoc.get_config(:default_param_name)'
          x << "l ||= GLoc.similar_language(c.params[#{name}]);"
        end
        # :check_cookie
        unless (v= options.delete(:check_cookie)) == false
          name= v ? ":#{v}" : 'GLoc.get_config(:default_cookie_name)'
          x << "l ||= GLoc.similar_language(c.send(:cookies)[#{name}]);"
        end
        # :check_accept_header
        unless options.delete(:check_accept_header) == false
          x << %<
              unless l
                a= c.request.env['HTTP_ACCEPT_LANGUAGE'].split(/,|;/) rescue nil
                a.each {|x| l ||= GLoc.similar_language(x)} if a
              end; >
        end
        # Set language
        x << 'ret= true;'
        x << 'if l; c.set_language(l); c.headers[\'Content-Language\']= l.to_s; '
        if options.has_key?(:on_set_lang)
          x << "ret= c.#{options.delete(:on_set_lang)}(l);"
        end
        if options.has_key?(:on_no_lang)
          x << "else; ret= c.#{options.delete(:on_no_lang)};"
        end
        x << 'end; ret }'
        
        # Create filter
        block= eval x
        before_filter(*args, &block)
      end

    end
  end
end

# ==============================================================================

module ActionMailer #:nodoc:
  # In addition to including GLoc, <tt>render_message</tt> is also overridden so
  # that mail templates contain the current language at the end of the file.
  # Eg. <tt>deliver_hello</tt> will render <tt>hello_en.rhtml</tt>.
  class Base
    include GLoc
    private
    alias :render_message_without_gloc :render_message
    def render_message(method_name, body)
      template = File.exist?("#{template_path}/#{method_name}_#{current_language}.rhtml") ? "#{method_name}_#{current_language}" : "#{method_name}"
      render_message_without_gloc(template, body)
    end
  end
end

# ==============================================================================

module ActionView #:nodoc:
  # <tt>initialize</tt> is overridden so that new instances of this class inherit
  # the current language of the controller.
  class Base
    include GLoc
    
    alias :initialize_without_gloc :initialize
    def initialize(base_path = nil, assigns_for_first_render = {}, controller = nil)
      initialize_without_gloc(base_path, assigns_for_first_render, controller)
      set_language controller.current_language unless controller.nil?
    end
  end
  
  module Helpers #:nodoc:
    class InstanceTag
      include GLoc
      # Inherits the current language from the template object.
      def current_language
        @template_object.current_language
      end
    end
  end
end

# ==============================================================================

module ActiveRecord #:nodoc:
  class Base #:nodoc:
    include GLoc
  end
end

# ==============================================================================

module ApplicationHelper #:nodoc:
  include GLoc
end
