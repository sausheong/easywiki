# settings
BOOTSTRAP_THEME = ENV['BOOTSTRAP_THEME'] || '//netdna.bootstrapcdn.com/bootswatch/2.3.0/journal/bootstrap.min.css'
WIKI_NAME = ENV['WIKI_NAME'] || 'EasyWiki'
WHITELIST = (ENV['WHITELIST'].nil? || ENV['WHITELIST'].empty? ? [] : ENV['WHITELIST'].split(','))

# helper module
module EasyHelper
  def format(content)
    Creole.creolize content
  end
  
  def snippet(page, options={})
    haml page, options.merge!(layout: false)
  end
    
  def toolbar
    haml :toolbar, layout: false
  end
  
  def must_login
    raise "You have not signed in yet. Please sign in first!" unless session[:user]
    true
  end
  
  def must_in_whitelist
    return true if WHITELIST.empty?
    raise "You are not allowed to do this." unless WHITELIST.include?(session[:user]['username'])
    true
  end
end

# models
DataMapper.setup(:default, ENV['DATABASE_URL'])

class Page
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime
  property :url, String, length: 255, unique: true
  
  property :user_name, String
  property :user_link, String  
  property :user_facebook_id, String
  
  has n, :versions, constraint: :destroy
  
  def latest
    versions.last.content unless versions.empty?       
  end
  
  def is_owned_by(user)
    self.user_facebook_id == user['id']
  end
end

class Version
  include DataMapper::Resource
  property :id, Serial
  property :created_at, DateTime
  property :content, Text
  
  property :user_name, String
  property :user_link, String  
  property :user_facebook_id, String
  
  belongs_to :page
end
DataMapper.finalize

#routes
configure do
  enable :sessions
  enable :inline_templates
  set :session_secret, ENV['SESSION_SECRET'] ||= 'sausheong_secret_stuff'
  set :show_exceptions, false
  
  # installation steps  
  unless DataMapper.repository(:default).adapter.storage_exists?('page')
    DataMapper.auto_upgrade!
    unless Page.count > 1
      page = Page.create url: 'Index'
      page.versions.create content: '', user_name: 'Wiki-owner'  
    end
  end
end

helpers EasyHelper

error Exception do
  @error = request.env['sinatra.error'].message
  haml :error
end

get "/" do
  @page = Page.first
  haml :index
end

get "/:url" do
  @page = Page.first(url: params[:url]) 
  if @page
    haml :index
  else
    @page = Page.new
    @page.url = params[:url]
    haml :edit
  end
end

get "/:url/edit" do
  must_login
  @page = Page.first url: params[:url]
  raise 'Cannot find this page' unless @page
  haml :edit
end

delete "/:url" do
  must_login
  raise 'You cannot delete the index page' if params[:url] == 'Index'
  page = Page.first url: params[:url]
  raise "You need to be the author of this page to remove it." unless page.user_facebook_id == session[:user]['id']
  page.destroy
  redirect "/"
end

post "/:url" do
  must_login and must_in_whitelist
  unless page = Page.first(url: params[:url])
    page = Page.create user_facebook_id: session[:user]['id'], user_name: session[:user]['name'], user_link: session[:user]['link'], url: params[:url]
  end
  version = page.versions.create user_facebook_id: session[:user]['id'], user_name: session[:user]['name'], user_link: session[:user]['link'], content: params[:content]
  redirect "/#{page.url}"
end

get '/page/sitemap' do
  @pages = Page.all
  haml :sitemap
end

get '/:url/history' do
  @page = Page.first url: params[:url]
  haml :history
end

get '/:url/history/:revision' do
  @page = Page.first url: params[:url]  
  @version = @page.versions.get params[:revision] 
  raise "You cannot do that on a page revision." unless @version
  @revision = @version == @page.versions.last ? "latest" : params[:revision]  
  haml :revision
end

get  '/:url/set-latest/:revision' do
  must_login
  page = Page.first url: params[:url]  
  version = page.versions.get params[:revision] 
  raise "No such revision." unless version
  page.versions.create user_facebook_id: session[:user]['id'], user_name: session[:user]['name'], user_link: session[:user]['link'], content: version.content
  redirect "/#{page.url}"  
end

get '/auth/login' do  
  RestClient.get "https://www.facebook.com/dialog/oauth",
                    params: {client_id: ENV['FACEBOOK_APP_ID'], 
                             redirect_uri: "#{request.scheme}://#{request.host}:#{request.port}/auth/callback"}
end

get '/auth/callback' do
  if params['code']
    resp = RestClient.get("https://graph.facebook.com/oauth/access_token",
                      params: {client_id: ENV['FACEBOOK_APP_ID'],
                               client_secret: ENV['FACEBOOK_APP_SECRET'],
                               redirect_uri: "#{request.scheme}://#{request.host}:#{request.port}/auth/callback",
                               code: params['code']})                                           
    session[:access_token] = resp.split("&")[0].split("=")[1]
    user = RestClient.get("https://graph.facebook.com/me?access_token=#{session[:access_token]}&fields=picture,name,username,link,timezone")
    session[:user] = JSON.parse user
    redirect "/"
  end
end

get "/auth/logout" do
  session.clear
  redirect "/"
end

__END__

@@ layout
!!! 1.1
%html{:xmlns => "http://www.w3.org/1999/xhtml"}
  %head
    %title=WIKI_NAME
    %meta{name: 'viewport', content: 'width=device-width, initial-scale=1.0, maximum-scale=1.0'}
    %link{rel: 'stylesheet', href: BOOTSTRAP_THEME, type: 'text/css'}
    %link{rel: 'stylesheet', href: "//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-responsive.min.css", type: 'text/css'}
    %link{rel: 'stylesheet', href: '//netdna.bootstrapcdn.com/font-awesome/3.0.2/css/font-awesome.css', type:  'text/css'}
    %link{rel: 'stylesheet', href: '//twitter.github.com/bootstrap/assets/js/google-code-prettify/prettify.css', type:  'text/css'}
    %link{rel: 'stylesheet', href: '//twitter.github.com/bootstrap/assets/css/docs.css', type:  'text/css'}
    %script{type: 'text/javascript', src: "//code.jquery.com/jquery-1.9.1.min.js"}    
    %script{type: 'text/javascript', src: "//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/js/bootstrap.min.js"}

  %body
    #fb-root   
    =toolbar
    =yield
    
    %br
    %footer
      %p.mute.footer 
        %small 
          &copy; 
          %a{href:'http://about.me/sausheong'} Chang Sau Sheong 
          2013

:css
  body { font-size: 20px; line-height: 26px; }
  .x-small {font-size: 0.75em; line-height: 1em}
  li {line-height: 1.4em}
  li > a {text-decoration: underline; }
  
@@ error
%section
  .container.content.center      
    %h1.text-error.text-center
      %i.icon-warning-sign
      Oops, there's been an error. 
    %br
    %p.lead.text-center
      =@error  

@@ toolbar
.navbar.navbar-fixed-top
  .navbar-inner
    .container

      %button.btn.btn-navbar.collapsed{'data-toggle' => 'collapse', 'data-target' => '.nav-collapse'}
        %span.icon-bar
        %span.icon-bar
        %span.icon-bar

      %ul.nav
        %a.brand{href:"/"}
          =WIKI_NAME

      .nav-collapse        
        %ul.nav
          %li.divider-vertical
          %li
            %a{href: "/page/sitemap"}
              %i.icon-sitemap
              Map
          - if @page
            %form.hide#delete{method: 'post', action: "/#{@page.url}"}
              %input{type: 'hidden', name: '_method', value: 'delete'}          
            %li
              %a{href: "/#{@page.url}/history"}
                %i.icon-time
                History

            - if session[:user]
              - if request.path.end_with?('edit')
                %li
                  %a{href: "/#{@page.url}"} 
                    %i.icon-eye-open
                    View               
              - else
                %li
                  %a{href: "/#{@page.url}/edit"} 
                    %i.icon-pencil
                    Edit 
                %li
                  %a{href:"#", onclick: "$('#delete').submit();"}
                    %i.icon-remove
                    delete              

        %ul.nav.pull-right
          - if session[:user]
            %li.dropdown
              %a.dropdown-toggle{:href => "#", 'data-toggle' => 'dropdown' }
                %i.icon-user
                =session[:user]['name']
                %span.caret
              %ul.dropdown-menu
                %li
                  %a{:href => '/auth/logout'} Sign out
          - else
            %li
              %a{:href => '/auth/login'} 
                %i.icon-facebook-sign
                Sign in

@@ history
%section
  .container.content
    .row
      .span12
        %h2           
          =@page.url
          \: Revision history
        %p.text-info.lead History of changes to this page.
      .span12
        %ul.unstyled
          - @page.versions.reverse.each do |version|
            %li
              %i.icon-time
              %a{href: "/#{@page.url}/history/#{version.id}"}=version.created_at.strftime('%e %b %Y, %l:%M %P')               
              by
              %a{href: version.user_link}
                =version.user_name || 'Not specified'

      .span12
        &nbsp;
      .span12
        %a.btn{href: "/#{@page.url}"}
          %i.icon-bookmark
          Go to current revision

@@ revision
%section
  .container.content
    .row
      .span12
        %h2
          =@page.url
          revision : (#{@revision})
        =format(@version.content)
      .span12
        &nbsp;
      .span12
        %p.muted.x-small
          %small
            Revision by 
            %a{href:@version.user_link}
              =@version.user_name || "Wiki-owner"
            =@version.created_at.strftime('%e %b %Y, %l:%M %P')
      .span12
        %a.btn{href: "/#{@page.url}/history"}
          %i.icon-arrow-left
          Back to revision history
          
        - if session[:user] and @revision != 'latest' 
          %a.btn{href: "/#{@page.url}/set-latest/#{@revision}"}
            %i.icon-asterisk
            Set this as latest revision

@@sitemap
%section
  .container.content
    .row
      .span12
        %h1
          %i.icon-sitemap
          All Pages
        %p.text-info.lead All pages in this wiki
      .span12
        %ul
          - @pages.each do |page|
            %li
              %a{href: "/#{page.url}"}=page.url

@@ index
%section
  .container.content
    .row
      .span12
        %h2=@page.url
        =format(@page.latest)

      .span12
        &nbsp;
      .span12
        %p.muted.x-small
          %small
            Created by 
            %a{href:@page.user_link}
              =@page.user_name || "Wiki-owner"
            =@page.created_at.strftime('%e %b %Y, %l:%M %P')
            %br
            Last modified by 
            %a{href:@page.versions.last.user_link}
              =@page.versions.last.user_name
            =@page.versions.last.created_at.strftime('%e %b %Y, %l:%M %P')

@@ new
%section
  .container.content
    %h1 
      %i.icon-plus-sign-alt
      New Page

    
    .row
      .span12
        %form{method: 'post', action: '/post'}
          %p.text-info.lead
            Type a new post into the fields and click on add to create it.
          =snippet :'post/_fields'
          
          .form-actions
            %input.btn.btn-primary{type: 'submit', value: 'Add'}
            %a.btn{href:'/'} Cancel

@@ edit  
%section
  .container.content
    %h2 
      %i.icon-pencil
      Edit Page: #{@page.url}
    .row
      .span12
        %form{method: 'post', action: "/#{@page.url}"}
          %p.text-info.lead
            Edit this page and click on the done button below.
          %textarea.span12{name: 'content', placeholder: 'Type your page contents here', rows: 25}~@page.latest

          %a{href: 'http://www.wikicreole.org/wiki/AllMarkup', target: '_blank'} 
            %i.icon-link
            Reference
          
          .form-actions
            %input.btn.btn-primary{type: 'submit', value: 'Done'}
            %a.btn{href: "/#{@page.url}"} Cancel

:css
  textarea {font-size: 0.9em; font-family: "Courier New", Courier, monospace; line-height: 1.1em; color: black;}