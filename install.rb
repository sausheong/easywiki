# to install do this - 
# > bundle exec irb -r ./install.rb

require 'data_mapper'
require 'sinatra'
require './easywiki'
DataMapper.auto_migrate!
page = Page.create url: 'Index'
page.versions.create content: '', user_name: 'Wiki-owner'
exit