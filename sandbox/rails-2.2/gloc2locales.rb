Dir.glob("lang/*.yml") do |file|
	#next if File.exist?("config/locales/#{File.basename(file)}")
	puts file
  raw = File.read(file)
  strings = YAML::load(raw)
  file =~ %r{(\w+)\.yml}
  lang = $1
  
  if File.exist?("config/locales/#{File.basename(file)}")
    File.open("config/locales/#{File.basename(file)}", 'a') do |f|
      f.write "\n"
      f.write <<"EOF"
  activerecord:
    errors:
      messages:
        greater_than_start_date: "#{strings['activerecord_error_greater_than_start_date']}"
        not_same_project: "#{strings['activerecord_error_not_same_project']}"
        circular_dependency: "#{strings['activerecord_error_circular_dependency']}"
EOF
    end
  else
    File.open("config/locales/#{File.basename(file)}", 'w') do |f|
      f.write <<"EOF"
#{lang}:
  activerecord:
    errors:
      messages:
        inclusion: "#{strings['activerecord_error_inclusion']}"
        exclusion: "#{strings['activerecord_error_exclusion']}"
        invalid: "#{strings['activerecord_error_invalid']}"
        confirmation: "#{strings['activerecord_error_confirmation']}"
        accepted: "#{strings['activerecord_error_accepted']}"
        empty: "#{strings['activerecord_error_empty']}"
        blank: "#{strings['activerecord_error_blank']}"
        too_long: "#{strings['activerecord_error_too_long']}"
        too_short: "#{strings['activerecord_error_too_short']}"
        wrong_length: "#{strings['activerecord_error_wrong_length']}"
        taken: "#{strings['activerecord_error_taken']}"
        not_a_number: "#{strings['activerecord_error_not_a_number']}"
        not_a_date: "#{strings['activerecord_error_not_a_date']}"
        greater_than: "must be greater than {{count}}"
        greater_than_or_equal_to: "must be greater than or equal to {{count}}"
        equal_to: "must be equal to {{count}}"
        less_than: "must be less than {{count}}"
        less_than_or_equal_to: "must be less than or equal to {{count}}"
        odd: "must be odd"
        even: "must be even"
        greater_than_start_date: "#{strings['activerecord_error_greater_than_start_date']}"
        not_same_project: "#{strings['activerecord_error_not_same_project']}"
        circular_dependency: "#{strings['activerecord_error_circular_dependency']}"
EOF
    end
  end
  
	File.open("config/locales/#{File.basename(file)}", 'a') do |f|
    f.write "\n"

    raw.each_line do |line|
      next if line =~ /_gloc/
      
      line.gsub!(/^notice_failed_to_save_issues: "?(.*)%d(.*)%d(.*)%s(.*)"? *$/o, 'notice_failed_to_save_issues: "\\1{{count}}\\2{{total}}\\3{{ids}}\\4"')
      line.gsub!(/^mail_body_reminder: "?(.*)%d(.*)%d(.*)"? *$/o, 'mail_body_reminder: "\\1{{count}}\\2{{days}}\\3"')
      line.gsub!(/^label_(added|updated)_time_by: "?(.*)%s(.*)%s(.*)"? *$/o, 'label_\\1_time_by: "\\2{{author}}\\3{{age}}\\4"')
      line.gsub!(/^text_journal_changed: "?(.*)%s(.*)%s(.*)"? *$/o, 'text_journal_changed: "\\1{{old}}\\2{{new}}\\3"')
      line.gsub!(/^text_length_between: "?(.*)%d(.*)%d(.*)"? *$/o, 'text_length_between: "\\1{{min}}\\2{{max}}\\3"')
      line.gsub!(/^text_issue_(added|updated): "?(.*)%s(.*)%s(.*)"? *$/o, 'text_issue_\\1: "\\2{{id}}\\3{{author}}\\4"')
      
      if line =~ /^([\w_]+): ['"]?(.*)%(d|s)(.*)['"]? *$/
        line.gsub!('"', '')
        line.gsub!(/^([\w_]+): ['"]?(.*)%d(.*)['"]? *$/, '\\1: "\\2{{count}}\\3"')
        line.gsub!(/^([\w_]+): ['"]?(.*)%s(.*)['"]? *$/, '\\1: "\\2{{value}}\\3"')
      end
      
      line.gsub!(/"+/, '"')
      f.write '  ' + line
    end
	end
end

Dir.glob("config/locales/*.yml") do |file|
  puts "Loading #{file}..."
  YAML::load(File.read(file))
end