require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :session


def generate_id(arr)
    id = session[:id]
    p id
    #index=arr.find_index(id)
    #arr = arr.delete_at(index)
    selected_id = arr.sample
    return selected_id
end

get('/hird/signup') do
    slim(:"/new_user")
end

post('/hird/signup') do
    user = params["user"]
    pwd = params["pwd"]
    pwd_confirm = params["pwd_confirm"]

    db = SQLite3::Database.new("db/databas.db")
    result=db.execute("SELECT id store WHERE users=?",user)

    if pwd==pwd_confirm
        pwd_digest=BCrypt::Password.create(pwd)
        db.execute("INSERT INTO store (users,pwd_digest) VALUES(?,?)",[user,pwd_digest])
        redirect('/hird')
    else
        redirect('/error')
    end
end
get('/hird/login') do
    slim(:"/login")
end

get('/') do
    redirect('/hird')
end

get('/hird/:id') do
    id = params[:id].to_i
    puts id
    session[:id] = id
    db = SQLite3::Database.new("db/databas.db")
    @selected_user = db.execute("SELECT user FROM individual WHERE id = ?", id).flatten[0]
    slim(:"/index")
end

post('/hird/ignore') do
    db = SQLite3::Database.new("db/databas.db")
    id_arr = db.execute("SELECT id FROM individual").flatten
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