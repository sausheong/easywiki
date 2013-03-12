# settings
BOOTSTRAP_THEME = ENV['BOOTSTRAP_THEME'] || '//netdna.bootstrapcdn.com/twitter-bootstrap/2.3.1/css/bootstrap-combined.no-icons.min.css'
WIKI_NAME = ENV['WIKI_NAME'] || 'EasyWiki'
WHITELIST = ENV['WHITELIST'].split(',') || []

# helper module
module EasyHelper
  def format(content)
    # Redcarpet::Markdown.new(Redcarpet::Render::HTML, 
    #                         autolink: true, 
    #                         space_after_headers: true,
    #                         tables: true).render(content)
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
    raise "No one in the whitelist yet." if WHITELIST.empty?
    raise "You are not allowed to do this." unless WHITELIST.include?(session[:user]['username'])
    true
  end
end

# models
DataMapper.setup(:default, ENV['POSTGRES_STRING'])

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
  set :session_secret, ENV['SESSION_SECRET'] ||= 'sausheong_secret_stuff'
  set :show_exceptions, false
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
  must_login and must_in_whitelist
  raise 'You cannot delete the index page' if params[:url] == 'index'
  page = Page.first url: params[:url]
  raise "You need to be the author of this page to remove it." unless page.user_facebook_id == session[:user]['id']
  page.destroy
  redirect "/"
end

post "/:url" do
  must_login 
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