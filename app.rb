require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'

enable :sessions

def generate_id(arr)
    id = session[:id]
    #p id
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
    result=db.execute("SELECT id FROM users WHERE user=?",user)
    if result.empty?
        if pwd==pwd_confirm
            pwd_digest=BCrypt::Password.create(pwd)
            db.execute("INSERT INTO users (user,pwd_digest) VALUES(?,?)",[user,pwd_digest])

            redirect("/dashboard")
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
    db.results_as_hash = true
    
    result=db.execute("SELECT id,pwd_digest FROM users WHERE user=?",user)

    if result.empty?
        redirect('/error')
        return
    end
    
    user_id = result.first["id"]
    pwd_digest = result.first["pwd_digest"]
    
    if BCrypt::Password.new(pwd_digest) == pwd
        
        session[:user_id] = user_id
        redirect("/dashboard")
    else
        redirect('/error')
    end

end
@username = nil

get('/dashboard') do
    user_id = session[:user_id]
    db = SQLite3::Database.new("db/databas.db")
    @username=db.execute("SELECT user FROM users WHERE id=?",user_id)
    slim(:"/dashboard")
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
    #p session[:user_id]
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
    id = params[:id].to_i    
    db.results_as_hash = true
    #p id
    login_id = session[:user_id]
    #if db.execute("SELECT type FROM users WHERE id = ?", id) == "employer"
    #user = db.execute("SELECT user FROM individual WHERE id = ?", id)

    #ändra databas i framtiden
    db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_e,match_status_i) VALUES (?,?,?,?)",[login_id, id, 1,1])
    id_arr = db.execute("SELECT id FROM individual").flatten
    redirect("/hird/#{generate_id(id_arr)}")
end

