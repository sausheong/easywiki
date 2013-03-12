require 'data_mapper'
require 'sinatra'
require './easywiki'
DataMapper.auto_migrate!
page = Page.create url: 'index'
page.versions.create content: '', user_name: 'Wiki-owner'
exit