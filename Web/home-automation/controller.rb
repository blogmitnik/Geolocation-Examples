# This is an example of the glue between Geoloqi triggers and an X10 controller.
# Set up a Sinatra project, and use this class as the main class.
# See https://github.com/geoloqi/MapAttack for an example of using Sinatra and the Geoloqi class.

# Please note, this is mostly untested code put together from a few different sources.
# You may have trouble running it as is, so please feel free to contribute back if you 
# fix anything.

# Download the cm17a library from http://x10-cm17a.rubyforge.org/
require 'x10/cm17a'

class Controller < Sinatra::Base

  before do
  	@redirect_uri = request.scheme + '://' + request.host_with_port + '/oauth'
  	@trigger_uri = request.scheme + '://' + request.host_with_port + '/trigger'
    redirect geoloqi.authorize_url(@redirect_uri) unless geoloqi.access_token?
  end

  after do
    session[:geoloqi_auth] = geoloqi.auth
  end
  
  get '/?' do
    erb :'index'
  end

  # OAuth endpoint, see https://developers.geoloqi.com/api/Authentication for more information
  get '/oauth' do 
    # If we're coming back from the OAuth authorization, there will be a 'code' parameter in the query string
    if params[:code]
      # Take the code and use it to get an access token, store it in the session
      session[:geoloqi_auth] = geoloqi.get_auth(params[:code], @redirect_uri)
      redirect '/'
    else
      # If no code was in the query string, redirect to the authorization endpoint
      redirect geoloqi.authorize_url(@redirect_uri)
    end
  end

  # Run this once to create the layer in Geoloqi, create a "Home" and a "Work" place, and set up the triggers
  get '/setup' do

    # Create the layer and store the response which has the layer ID    
    layer = geoloqi.post 'layer/create', {
      :name => "Home Automation",
      :description => "My Home Automation Layer"
    }

    # Create a place called "Home"
    geoloqi.post 'place/create', {
      :layer_id => layer.layer_id,
      :name => "Home",
      :latitude => 47.6170,     # Replace with your lat/lng
      :longitude => -122.3404,
      :radius => 150
    }

    # Create a place called "Work"
    geoloqi.post 'place/create', {
      :layer_id => layer.layer_id,
      :name => "Work",
      :latitude => 47.613,     # Replace with your lat/lng
      :longitude => -122.333,
      :radius => 150
    }
    
    # Create a trigger for the layer which will be called 
    # when you enter any of the places
    geoloqi.post 'trigger/create', {
      :layer_id => layer.layer_id,
      :type => 'callback',
      :callback => @trigger_uri,
      :trigger_on => 'enter'
    }

    # Create a trigger for the layer which will be called 
    # when you leave any of the places
    geoloqi.post 'trigger/create', {
      :layer_id => layer.layer_id,
      :type => 'callback',
      :callback => @trigger_uri,
      :trigger_on => 'exit'
    }
  
  end

  # This will be called by Geoloqi whenever you enter or leave 
  # a place on the layer
  post '/trigger' do
    body = Hashie::Mash.new JSON.parse(request.body)

    lamp = X10.device('a1')  # Create an X10 device at address 'a1'
    
    case body.place.name

      when "Home"
        if(body.triggered_on == "enter")
          # Turn the device on when getting home
          lamp.on
          SMSified.send "+13605551212", "Honey, I'm home!"
        else
          # Turn the device off when leaving
          lamp.off
        end

      when "Work"
        if(body.triggered_on == "enter")
          SMSified.send "+13605551212", "I'm at work!"
        else
          # Message somebody when you are leaving work
          SMSified.send "+13605551212", "I'm on my way home!"
        end
    end
  end

end
