require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'

configure do
  enable :sessions
  set :session_secret, 'afb00d68fbae86e81ff2fe04c3206bba5f0c4165401c3d1bf3e8fdbe222d2081'
end

before do
  session[:lists] ||= []
end

get "/" do
  redirect "/lists"
end

get "/lists" do
  @lists = session[:lists]
  erb :lists
end

post "/lists" do
  session[:lists] << { name: params[:list_name], todos: [] }
  session[:success] = "New list added!"
  redirect "/lists"
end

get "/lists/new" do
  erb :new_list
end

get "/lists/reset" do
  session[:lists] = []
  redirect "/lists"
end
