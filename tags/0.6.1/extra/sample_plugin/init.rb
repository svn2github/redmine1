# Redmine sample plugin
require 'redmine'

RAILS_DEFAULT_LOGGER.info 'Starting Example plugin for RedMine'

Redmine::Plugin.register :sample_plugin do
  name 'Example plugin'
  author 'Author name'
  description 'This is a sample plugin for Redmine'
  version '0.0.1'
  settings :default => {'sample_setting' => 'value', 'foo'=>'bar'}, :partial => 'settings/settings'

  # This plugin adds a project module
  # It can be enabled/disabled at project level (Project settings -> Modules)
  project_module :example_module do
    # A public action
    permission :example_say_hello, {:example => [:say_hello]}, :public => true
    # This permission has to be explicitly given
    # It will be listed on the permissions screen
    permission :example_say_goodbye, {:example => [:say_goodbye]}
  end

  # A new item is added to the project menu
  menu :project_menu, :label_plugin_example, :controller => 'example', :action => 'say_hello'
end
