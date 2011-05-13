# This is an example of the glue between Geoloqi triggers and an X10 controller.
# Set up a Sinatra project, and use this class as the main class.
# See https://github.com/aaronpk/MapAttack for an example of using Sinatra and the Geoloqi class.

# Please note, this is mostly untested code put together from a few different sources.
# You may have trouble running it as is, so please feel free to contribute back if you 
# fix anything.

# Download the cm17a library from http://x10-cm17a.rubyforge.org/
require 'x10/cm17a'

class HomeAutomation < Sinatra::Base

  get '/?' do
    erb :'index'
  end

  # Run this once to create the layer in Geoloqi, create a "Home" and a "Work" place, and set up the triggers
  get '/setup' do
    @oauth_token = ""   # Put your permanent access token here for now. http://beta.geoloqi.com/settings/connections

    # Create the layer and store the response which has the layer ID    
    layer = Geoloqi.post @oauth_token, 'layer/create', {
      :name => "Home Automation",
      :description => "My Home Automation Layer"
    }

    # Create a place called "Home"
    Geoloqi.post @oauth_token, 'place/create', {
      :layer_id => layer.layer_id,
      :name => "Home",
      :latitude => 47.6170,     # Replace with your lat/lng
      :longitude => -122.3404,
      :radius => 150
    }

    # Create a place called "Work"
    Geoloqi.post @oauth_token, 'place/create', {
      :layer_id => layer.layer_id,
      :name => "Work",
      :latitude => 47.613,     # Replace with your lat/lng
      :longitude => -122.333,
      :radius => 150
    }
    
    # Create a trigger for the layer which will be called 
    # when you enter any of the places
    Geoloqi.post @oauth_token, 'trigger/create', {
      :layer_id => layer.layer_id,
      :type => 'callback',
      :callback => 'http://example.com:9292/trigger',
      :trigger_on => 'enter'
    }

    # Create a trigger for the layer which will be called 
    # when you leave any of the places
    Geoloqi.post @oauth_token, 'trigger/create', {
      :layer_id => layer.layer_id,
      :type => 'callback',
      :callback => 'http://example.com:9292/trigger',
      :trigger_on => 'exit'
    }
  
  end

  # Create a trigger in Geoloqi pointing back to this URL. This will be called by Geoloqi
  # whenever you enter or leave a place on the layer
  post '/trigger' do
    body = SymbolTable.new JSON.parse(request.body)

    lamp = X10.device('a1')  # Create an X10 device at address 'a1'
    
    case body.place.name

      when "Home"
        if(body.triggered_on == "enter")
          # Turn the device on when getting home
          lamp.on
        else
          # Turn the device off when leaving
          lamp.off
        end

      when "Work"
        if(body.triggered_on == "enter")

        else
          # Message somebody when you are leaving work
          SMSified.send "+13605551212", "I'm on my way home!"
        end
    end
  end

end
