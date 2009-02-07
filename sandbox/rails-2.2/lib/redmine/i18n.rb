module Redmine
  module I18n
    def l(*args)
      case args.size
      when 1
        ::I18n.t(*args)
      when 2
        if args.last.is_a?(Hash)
          ::I18n.t(*args)
        elsif args.last.is_a?(String)
          ::I18n.t(args.first, :value => args.last)
        else
          ::I18n.t(args.first, :count => args.last)
        end
      else
        raise "Translation string with multiple values: #{args.first}"
      end
    end

    def l_or_humanize(s, options={})
      k = "#{options[:prefix]}#{s}".to_sym
      ::I18n.t(k, :default => s.to_s.humanize)
    end
    
    def lwr(str, count)
      count > 1 ? ::I18n.t("#{str}_plural", :count => count) : ::I18n.t(str, :count => count)
    end
    
    def ll(lang, str)
      ::I18n.t(str.to_s, :locale => lang.to_s.gsub(%r{(.+)\-(.+)$}) { "#{$1}-#{$2.upcase}" })
    end

    def format_date(date)
      return nil unless date
      Setting.date_format.blank? ? ::I18n.l(date.to_date) : date.strftime(Setting.date_format)
    end
    
    def format_time(time, include_date = true)
      return nil unless time
      time = time.to_time if time.is_a?(String)
      zone = User.current.time_zone
      local = zone ? time.in_time_zone(zone) : (time.utc? ? time.localtime : time)
      Setting.time_format.blank? ? ::I18n.l(local, :format => (include_date ? :default : :time)) : 
                                   ((include_date ? "#{format_date(time)} " : "") + "#{local.strftime(Setting.time_format)}")
    end
    
    def available_locales
      GLoc.valid_languages.collect(&:to_s).sort
    end
    
    def locale_exists?(locale)
      GLoc.valid_language?(locale.to_s)
    end
    
    def locale
      GLoc.current_language.to_s
    end
    
    def locale=(locale)
      GLoc.set_language_if_valid(locale.to_s)
    end
  end
end
