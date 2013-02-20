require 'sinatra'
require 'base64'
require 'json'
require 'open-uri'

get '/' do
  content_type 'application/json'

  url = request.env['QUERY_STRING'].split('=').last

  resp = Hash.new

  if url
    if url =~ /\.gif$/
      begin
        file = open url
      rescue
        resp[:error] = 'internal error'
      else
        if file.size > 1024*1024*5 # 5 mb
          resp[:error] = "image too big, limit is 5 megabytes"
        else
          resp[:response] ='data:image/gif;base64,' + Base64.encode64(file.read)
        end
      end
    else
      resp[:error] = "it is not gif image, therefore go use your computer, dude!"
    end
  else
    resp[:response] = 'hello from ctrl-vk'
  end

  resp.to_json
end