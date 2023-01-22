# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'

configure do
  enable :sessions
  set :session_secret, 'afb00d68fbae86e81ff2fe04c3206bba5f0c4165401c3d1bf3e8fdbe222d2081'
  set :erb, :escape_html => true
end

before do
  session[:lists] ||= []
end

helpers do
  def list_complete?(list)
    list[:todos].size > 0 && list[:todos].all? { |x| x[:completed] == true }
  end

  def sort_lists(arr, &block)
    incomplete = []
    complete = []
    arr.each do |list|
      if list_complete?(list)
        complete << list
      else
        incomplete << list
      end
    end
    complete.each(&block)
    incomplete.each(&block)
  end
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

def get_next_id(arr)
  max = arr.map { |item| item[:id].to_i }.max || 0
  max + 1
end

post '/lists' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  if error
    session[:error] = error
    erb :new_list
  else
    id = get_next_id(session[:lists])
    session[:lists] << { id: id, name: list_name, todos: [] }
    session[:success] = 'New list added!'
    redirect '/lists'
  end
end

get '/lists/new' do
  erb :new_list
end

get '/lists/reset' do
  session[:lists] = []
  session[:success] = "All lists deleted."
  redirect '/lists'
end

get '/lists/:id' do
  @id = params[:id].to_i
  @list = session[:lists].select {|x| x[:id] == @id }.first
  if @id >= get_next_id(session[:lists])
    session[:error] = "The specified list was not found."
    redirect "/lists"
  end
  erb :list
end

get '/lists/:id/edit' do
  @id = params[:id].to_i
  @list = session[:lists].select {|x| x[:id] == @id }.first
  erb :edit_list
end

post '/lists/:id' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  @id = params[:id].to_i
  @list = session[:lists].select {|x| x[:id] == @id }.first

  if error
    session[:error] = error
    erb :edit_list
  else
    @list[:name] = list_name
    session[:success] = 'Name changed!'
    redirect '/lists'
  end
end

post "/lists/:id/complete_all" do
  @id = params[:id].to_i
  @list = session[:lists].select {|x| x[:id] == @id }.first
  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All todos were checked as completed."
  redirect "/lists/#{@id}"
end

post '/lists/:id/delete' do
  @id = params[:id].to_i
  removed = session[:lists].delete_if { |x| x[:id] == @id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    "/lists"
  else
    session[:success] = "Todo list has been deleted."
    redirect "/lists"
  end
end

def error_for_todo(name)
  if !(1..100).cover? name.length
    'Todo text must be between 1 and 100 characters.'
  end
end

post "/lists/:id/todos" do
  @id = params[:id].to_i
  text = params[:todo].strip
  @list = session[:lists].select {|x| x[:id] == @id }.first
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list
  else
    id = get_next_id(@list[:todos])
    @list[:todos] << { id: id, name: text, completed: false }
    session[:success] = "New todo added!"
    redirect "/lists/#{@id}"
  end
end

post "/lists/:id/todos/:todo_id/delete" do
  @id = params[:id].to_i
  @todo_id = params[:todo_id].to_i
  @list = session[:lists].select {|x| x[:id] == @id }.first
  @list[:todos].delete_if { |x| x[:id] == @todo_id }
  if env["HTTP_X_REQUESTED_WITH"] == "XMLHttpRequest"
    status 204
  else
    session[:success] = "Todo was removed."
    redirect "/lists/#{@id}"
  end
end

post "/lists/:id/todos/:todo_id" do
  intended_status = params[:completed] == 'true'
  @id = params[:id].to_i
  @todo_id = params[:todo_id].to_i
  @list = session[:lists].select {|x| x[:id] == @id }.first
  @list[:todos][@todo_id][:completed] = intended_status #FIX
  session[:success] = "Todo has been updated."
  redirect "/lists/#{@id}"
end
