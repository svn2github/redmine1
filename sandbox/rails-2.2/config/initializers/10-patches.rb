
require 'activerecord'

module ActiveRecord
  class Base
    # Translate attribute names for validation errors display
    def self.human_attribute_name(attr)
      GLoc.l("field_#{attr}")
    end
  end
end

ActionView::Base.field_error_proc = Proc.new{ |html_tag, instance| "#{html_tag}" }

# Adds :async_smtp and :async_sendmail delivery methods
# to perform email deliveries asynchronously
module AsynchronousMailer
  %w(smtp sendmail).each do |type|
    define_method("perform_delivery_async_#{type}") do |mail|
      Thread.start do
        send "perform_delivery_#{type}", mail
      end      
    end
  end
end

ActionMailer::Base.send :include, AsynchronousMailer
