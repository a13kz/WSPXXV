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

get('/start/signup') do
    slim(:"/new_user")
end

post('/register') do
    user = params["user"]
    pwd = params["pwd"]
    pwd_confirm = params["pwd_confirm"]

    db = SQLite3::Database.new("db/databas.db")
    existing_user=db.execute("SELECT id FROM store WHERE users=?",user)
    if existing_user.empty?
        if pwd==pwd_confirm
            pwd_digest=BCrypt::Password.create(pwd)
            db.execute("INSERT INTO store (users,pwd_digest) VALUES(?,?)",[user,pwd_digest])
            id_arr = db.execute("SELECT id FROM individual").flatten
            redirect("/hird/#{generate_id(id_arr)}")
        else
            redirect('/error')
        end
    else
        redirect('/start/login')
    end
    
end

post('/login') do

    user = params["user"]
    pwd = params["pwd"]
    db = SQLite3::Database.new("db/databas.db")
    result=db.execute("SELECT id store WHERE users=?",user)

end

get('/start/login') do
    slim(:"/login")
end

get('/start') do
    slim(:"/start")
end

get('/hird') do
    slim(:"/logged_in")
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