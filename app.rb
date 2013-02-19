require 'sinatra'
require 'base64'
require 'json'
require 'open-uri'
require 'pry'

get '/' do
  url = request.env['QUERY_STRING'].split('=').last

  resp = Hash.new

  if url
    if url =~ /\.gif$/
      resp[:response] ='data:image/gif;base64,' + Base64.encode64(open(url) { |io| io.read })
    else
      resp[:error] = "it is not gif image, therefore go use your computer, dude!"
    end
  else
    resp[:response] = 'hello from ctrl-vk'
  end

  resp.to_json
end