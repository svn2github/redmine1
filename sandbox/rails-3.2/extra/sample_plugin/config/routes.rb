# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

match 'example/hello', :to => 'example#say_hello', :via => 'get'
match 'example/bye', :to => 'example#say_goodbye', :via => 'get'

resources 'meetings'
