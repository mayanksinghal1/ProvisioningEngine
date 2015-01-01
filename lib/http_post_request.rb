class HttpPostRequest
  def perform(action, uriString=ENV["PROVISIONINGENGINE_CAMEL_URL"], httpreadtimeout=4*3600, httpopentimeout=6)
    #
    # renders action="param1=value1, param2=value2, ..." and sends a HTTP POST request to uriString (default: "http://localhost/CloudWebPortal")
    #

    require "net/http"
    require "uri"
    
    uri = URI.parse(uriString)
    
    #response = Net::HTTP.post_form(uri, {"testMode" => "testMode", "offlineMode" => "offlineMode", "action" => "Add Customer", "customerName" => @customer.name})
    #OV replaced by (since I want to control the timers):
    http = Net::HTTP.new(uri.host, uri.port)
    http.open_timeout = httpopentimeout
    http.read_timeout = httpreadtimeout
    request = Net::HTTP::Post.new(uri.request_uri)
    #requestviatyphoeus = Typhoeus::Request.new("http://localhost/CloudWebPortal")

    array = action.split(/,/) #.map(&:strip) #seems to lead sporadically to action=Show Sites to be converted to 'Show Sites' => '' instead of 'action' => 'Show Sites' during Site synchronization
#    p '+++++++++++++++++++++++++  action.split(/,/) ++++++++++++++++++++++++++++++++'
#    p array.inspect
#    p array.map(&:strip).inspect
    
    #array = array.map(&:strip)
    
    postData = {}

    while array[0]
      variableValuePairArray = array.shift.split(/=/).map(&:strip)
#      p '+++++++++++++++++++++++++  variableValuePairArray ++++++++++++++++++++++++++++++++'
#      p variableValuePairArray.inspect
      if variableValuePairArray.length.to_s[/^2$/]
        postData[variableValuePairArray[0]] = variableValuePairArray[1]
      elsif variableValuePairArray.length.to_s[/^1$/]
        postData[variableValuePairArray[0]] = ""
      else
        abort "action (here: #{action}) must be of the format \"variable1=value1,variable2=value2, ...\""
      end
    end
    
    p "------------- HttpPostRequest POST Data to #{uriString} -----------------"
    p postData.inspect
    p '----------------------------------------------------------'
    
    request.set_form_data(postData)
    
    begin
      response = http.request(request)
      responseBody = response.body
    rescue
      responseBody = nil
    end
    
    return responseBody
  end # def perform
end
