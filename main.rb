require 'rubygems'
require 'sinatra'

#set :sessions, true
use Rack::Session::Cookie, :key => 'rack.session',
                           :path => '/',
                           :secret => 'dawnsecret' 


get '/text' do
  "I am simply rendering text from main.rb"
end

get '/template' do
  erb :mytemplate
end

get '/nested' do
  erb :'/users/nested_template'
end   

