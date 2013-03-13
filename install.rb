require 'rest_client'
require 'json'

puts "=="
puts "Installation script for EasyWiki"
puts
# configure variable below
HEROKU_API = ''
FACEBOOK_APP_ID = ''
FACEBOOK_APP_SECRET = ''

# installation script executes from here
heroku_url = "https://:#{HEROKU_API}@api.heroku.com/apps"

# Create app
response = RestClient.post heroku_url, "app[stack]=cedar", "Accept"=>"application/json"
app = JSON.parse response
puts "Creating app #{app['name']} is #{app['create_status']}"

# Add the Heroku Postgres:Dev addon
response = RestClient.post "#{heroku_url}/#{app['name']}/addons/heroku-postgresql:dev", "Accept"=>"application/json"
addon = JSON.parse response
puts "Postgres DB is #{addon['status']}"

# Set the configurations
config = {'FACEBOOK_APP_ID' => FACEBOOK_APP_ID, 'FACEBOOK_APP_SECRET' => FACEBOOK_APP_SECRET}
response = RestClient.put "#{heroku_url}/#{app['name']}/config_vars", config.to_json, "Accept"=>"application/json"
puts "Setting configurations at server are:"
puts response

# Push the code up to Heroku
system "git remote add heroku #{app['git_url']}"
system "git push heroku master"

# Show the final url
puts "== Installation complete =="
puts "Your new wiki is now installed at the URL below:"
puts
puts app['web_url']
puts
puts "Please remember to set your Facebook app to integrate with your wiki through 'Website with Facebook Login', with the Site URL set to http://#{app['name']}.herokuapp.com:80/"
puts
