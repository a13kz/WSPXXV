require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :session

get('/') do
    redirect('/hird')
end

get('/hird/:id') do
    id = params[:id].to_i
    db = SQLite3::Database.new("db/databas.db")
    @user = db.execute("SELECT user FROM individual WHERE id = ?", id)
    slim(:"/index")
end