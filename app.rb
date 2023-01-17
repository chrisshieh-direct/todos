require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

get "/" do
    erb "You have no list dude."
end
