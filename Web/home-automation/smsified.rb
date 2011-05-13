require "base64"

# Sign up at https://smsified.com

module SMSified
  class Error < StandardError
    def initialize(type, message=nil)
      type += " - #{message}" if message
      super type
    end
  end

  username = 'SMSified username'
  password = 'SMSified password'
  fromnumber = '1360999999'       # Your SMSified SMS number

  def self.send(to, message)
    args = {
      :head => {
        'Authorization' => base64.encode64(username + ':' + password)
      },
      :body => {
        :address => to,
        :message => message
      }.to_json
    }
    url = 'https://api.smsified.com/v1/smsmessaging/outbound/' + fromnumber + '/requests'
    response = JSON.parse EM::Synchrony.sync(EventMachine::HttpRequest.new(url).post(args)).response
    
    raise Error.new(response['error'], response['error_description']) if response.is_a?(Hash) && response['error']
    
    case response
    when Array
      response.map! {|e| SymbolTable.new e}
    when Hash
      SymbolTable.new response
    end
  end
end