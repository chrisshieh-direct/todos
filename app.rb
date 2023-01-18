# frozen_string_literal: true

require 'sinatra'
require 'sinatra/reloader' if development?
require 'tilt/erubis'
require 'sinatra/content_for'

configure do
  enable :sessions
  set :session_secret, 'afb00d68fbae86e81ff2fe04c3206bba5f0c4165401c3d1bf3e8fdbe222d2081'
end

before do
  session[:lists] ||= []
end

helpers do
  def list_complete?(list)
    list[:todos].size > 0 && list[:todos].all? { |x| x[:completed] == true }
  end

  def sort_lists(arr, &block)
    incomplete = {}
    complete = {}
    arr.each_with_index do |list, idx|
      if list_complete?(list)
        complete[list] = idx
      else
        incomplete[list] = idx
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
  session[:success] = "All lists deleted."
  redirect '/lists'
end

get '/lists/:id' do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :list
end

get '/lists/:id/edit' do
  @id = params[:id].to_i
  @list = session[:lists][@id]
  erb :edit_list
end

post '/lists/:id' do
  list_name = params[:list_name].strip
  error = error_for_list_name(list_name)
  @id = params[:id].to_i
  @list = session[:lists][@id]

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
  @list = session[:lists][@id]
  @list[:todos].each { |todo| todo[:completed] = true }
  session[:success] = "All todos were checked as completed."
  redirect "/lists/#{@id}"
end

post '/lists/:id/delete' do
  @id = params[:id].to_i
  removed = session[:lists].delete_at(@id)
  session[:success] = "Todo List '#{removed[:name]}' deleted."
  redirect "/lists"
end

def error_for_todo(name)
  if !(1..100).cover? name.length
    'Todo text must be between 1 and 100 characters.'
  end
end

post "/lists/:id/todos" do
  @id = params[:id].to_i
  text = params[:todo].strip
  @list = session[:lists][@id]
  error = error_for_todo(text)
  if error
    session[:error] = error
    erb :list
  else
    @list[:todos] << { name: text, completed: false }
    session[:success] = "New todo added!"
    redirect "/lists/#{@id}"
  end
end

post "/lists/:id/todos/:todo_id/delete" do
  @id = params[:id].to_i
  @todo_id = params[:todo_id].to_i
  session[:lists][@id][:todos].delete_at(@todo_id)
  session[:success] = "Todo was removed."
  redirect "/lists/#{:id}"
end

post "/lists/:id/todos/:todo_id" do
  intended_status = params[:completed] == 'true'
  @id = params[:id].to_i
  @todo_id = params[:todo_id].to_i
  session[:lists][@id][:todos][@todo_id][:completed] = intended_status
  session[:success] = "Todo has been updated."
  redirect "/lists/#{@id}"
end
