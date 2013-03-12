# EasyWiki

EasyWiki is a all-in-a-file wiki web app written in Ruby. What that means is that the entire web application is written into a single file that's ~400 lines of code. It's meant to be easy to deploy, maintain and extend.

## Features

* Authentication through Facebook sign in
* Only authenticated users can contribute to EasyWiki
* Only the author of a page can delete the page
* Has a sitemap of all pages
* Write wiki pages using [[http://www.wikicreole.org|Creole]] wiki syntax 
* Editing a page creates new version of the page
* Keeps a revision history of all versions to any page
** Can view any past revision
** Can set the page back to any past revision

## How to install on Heroku

You need these few things.

### Facebook app

EasyWiki integrates with Facebook for authentication. Create a Facebook app through http://developers.facebook.com. Then look out for the *App ID* and *App Secret*. Use the values to set the environment variables *FACEBOOK_APP_ID* and *FACEBOOK_APP_SECRET* accordingly.

Don't like Facebook? Deal with it, or modify it to integrate with what you like or write your own authentication mechanism. Simply change the `/auth/login` route and there you go.

### Relational database

I used Postgres, specifically, Heroku Postgres from http://postgres.heroku.com for persistent storage, along with DataMapper. They have a free dev database, if you don't feel like paying for one. Create the database string. It should be in the form `postgres://<username>:<password>@<hostname>:<port>/<database>`. The set the environment variable `POSTGRES_STRING`
  
## Whitelist of authors

By default anyone can write in the wiki, as long as they authenticate themselves first (with Facebook). Optionally you can set it such that only certain people in your whitelist of authors can write. Set the environment variable `WHITELIST` to a comma-delimited list of Facebook usernames (no spaces before or after the comma please). If you want to be the only one who can write, just put in your Facebook username. For eg. my Facebook username is 'sausheong' so that's the `WHITELIST` setting for me. Once you have done that, only people in the whitelist can write into the wiki. 

## Other settings

Only the Facebook and relational DB are needed, everything else is optional (except maybe). Here are some other environment variables you might want to set:

* `BOOTSTRAP_THEME` - A URL to the Bootstrap CSS stylesheet you want to use instead of the default. I used the *Journal* theme from Bootswatch. The default is the default Bootstrap stylesheet
* `WIKI_NAME` - A string to name your wiki. The default is 'EasyWiki'  

## To set environment variables in Heroku

Add the configuration settings using `heroku config:add <env variable>=<value>`. For a fuller explanation please refer to https://devcenter.heroku.com/articles/config-vars
  
## Installing on Heroku

Assuming you have a Heroku account, have the Heroku toolbelt installed, do the following to a wiki called MyWiki:

    > git clone https://github.com/sausheong/easywiki.git
    Cloning into 'mywiki'...
    remote: Counting objects: 37, done.
    remote: Compressing objects: 100% (27/27), done.
    remote: Total 37 (delta 11), reused 32 (delta 9)
    Unpacking objects: 100% (37/37), done.  
    > heroku create mywiki
    Creating mywiki... done, stack is cedar
    http://mywiki.herokuapp.com/ | git@heroku.com:mywiki.git
    Git remote heroku added
    > git push heroku master
    Counting objects: 37, done.
    Delta compression using up to 4 threads.
    Compressing objects: 100% (36/36), done.
    Writing objects: 100% (37/37), 11.43 KiB, done.
    Total 37 (delta 11), reused 0 (delta 0)

    -----> Ruby/Rack app detected
    -----> Installing dependencies using Bundler version 1.3.2
           Running: bundle install --without development:test --path vendor/bundle --binstubs vendor/bundle/bin --deployment
           Fetching gem metadata from https://rubygems.org/.........
           ...
           Cleaning up the bundler cache.
    -----> Discovering process types
           Procfile declares types     -> (none)
           Default types for Ruby/Rack -> console, rake, web

    -----> Compiled slug size: 3.6MB
    -----> Launching... done, v4
           http://mywiki.herokuapp.com deployed to Heroku

    To git@heroku.com:mywiki.git
     * [new branch]      master -> master
     > heroku config:add FACEBOOK_APP_ID=xxx
     Setting config vars and restarting mywiki... done, v5
     FACEBOOK_APP_ID: xxx
     > heroku config:add FACEBOOK_APP_SECRET=xxx
     Setting config vars and restarting mywiki... done, v6
     FACEBOOK_APP_SECRET: xxx
     > heroku config:add POSTGRES_STRING=xxx
     Setting config vars and restarting mywiki... done, v7
     POSTGRES_STRING: xxx
     >


