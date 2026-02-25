require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :session


def generate_id(arr)
    selected_id = arr.sample
return selected_id
end

get('/') do
    redirect('/hird')
end
@selected_user = "alex"
get('/hird/:id') do
    id = params[:id].to_i
    @id = id
    db = SQLite3::Database.new("db/databas.db")
    @selected_user = db.execute("SELECT user FROM individual WHERE id = ?", id)
    puts @selected_user
    slim(:"/index")
end

post('/hird/ignore') do
    db = SQLite3::Database.new("db/databas.db")
    id_arr = db.execute("SELECT id FROM individual")
    redirect("/hird/#{generate_id(id_arr)}")
end

post('/hird/add') do
    db = SQLite3::Database.new("db/databas.db")
    #id = params[:id].to_i
    login_id = 6
    selected_user_id = 0
    #db.execute("SELECT user FROM individual WHERE id = ?", id)
    db.results_as_hash = true
    #ändra databas i framtiden
    db.execute("INSERT INTO relation_list (individual_id,employer_id,match_status_e) VALUES (?,?,?)",[selected_user_id,login_id,1])
    redirect('/hird')
end