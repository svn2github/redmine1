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
    
    def lwr(*args)
      GLoc.lwr(*args)
    end
    
    def ll(*args)
      GLoc.ll(*args)
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
