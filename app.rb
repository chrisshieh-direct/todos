# frozen_string_literal: true

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

get '/' do
  redirect '/lists'
end

get '/lists' do
  @lists = session[:lists]
  erb :lists
end

def error_for_list_name(name)
  if !(1..100).cover? name.length
    'List name must be between 1 and 100 characters.'
  elsif session[:lists].any? { |list| list[:name] == name }
    'List name must be unique.'
  end
end

post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    session[:lists] << { name: list_name, todos: [] }
    session[:success] = 'New list added!'
    redirect '/lists'
  end
end

get '/lists/new' do
  erb :new_list
end

get '/lists/reset' do
  session[:lists] = []
  redirect '/lists'
end

get '/lists/:id' do
  @list = session[:lists][params[:id].to_i]
  erb :list
end
