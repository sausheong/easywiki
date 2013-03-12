require 'rest_client'
require 'json'

# configure variable below
HEROKU_API = ''
FACEBOOK_APP_ID = ''
FACEBOOK_APP_SECRET = ''

# installation script executes from here
# Create app
heroku_url = "https://:#{HEROKU_API}@api.heroku.com/apps"
response = RestClient.post heroku_url, "app[stack]=cedar", "Accept"=>"application/json"
app = JSON.parse response

# Set the configurations
config = {'FACEBOOK_APP_ID' => FACEBOOK_APP_ID, 'FACEBOOK_APP_SECRET' => FACEBOOK_APP_SECRET}
response = RestClient.put "#{heroku_url}/#{app['name']}/config_vars", config.to_json, "Accept"=>"application/json"

# Push the code up to Heroku
system "git remote add heroku #{app['git_url']}"
system "git push heroku master"

# Show the final url
puts app['web_url']
