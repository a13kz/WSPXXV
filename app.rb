require 'sinatra'
require 'slim'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require './model.rb'

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
    type = params["type"]
    desc = params["desc"]
    
    db = SQLite3::Database.new("db/databas.db")
    result=db.execute("SELECT id FROM users WHERE user=?",user)
    if result.empty?
        if pwd==pwd_confirm
            pwd_digest=BCrypt::Password.create(pwd)
            db.execute("INSERT INTO users (user,pwd_digest) VALUES(?,?)",[user,pwd_digest])
            db.execute("INSERT INTO user_information (user,type,description) VALUES(?,?,?)",[user,type,desc])
            # fixa så man sparar user_id här
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
    #p result
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



get('/error') do
    time = Time.now()
    session[:old_time]
    slim(:"/error")
end

get('/dashboard') do
    if session[:user_id] == nil
        redirect('/start')
    end
    db = SQLite3::Database.new("db/databas.db")
    user_id = session[:user_id]
    @username=db.get_first_value("SELECT user FROM users WHERE id=?",user_id)
    @desc=db.get_first_value("SELECT description FROM user_information WHERE id=?",user_id)
    @type=db.get_first_value("SELECT type FROM user_information WHERE id=?",user_id)
    session[:type] = @type
    if @type == "emp"
        selected_ids=db.execute("SELECT individual_id FROM relation_list INNER JOIN user_information ON relation_list.employer_id = user_information.id AND match_status_e=1 AND match_status_i IS NULL")
        @selected_users = []
        selected_ids.each do |id|
            @selected_users.push(db.get_first_value("SELECT user FROM user_information WHERE id=?",id))
            p @selected_users
        end
        matched_ids=db.execute("SELECT individual_id FROM relation_list INNER JOIN user_information ON relation_list.employer_id = user_information.id AND match_status_e=1 AND match_status_i=1")
        @matched_users = []
        selected_ids.each do |id|
            @selected_users.push(db.get_first_value("SELECT user FROM user_information WHERE id=?",id))
            p @selected_users
        end
    else
        selected_ids=db.execute("SELECT employer_id FROM relation_list INNER JOIN user_information ON relation_list.individual_id = user_information.id AND match_status_i=1 AND match_status_e IS NULL")
        @selected_users = []
        selected_ids.each do |id|
            @selected_users.push(db.get_first_value("SELECT user FROM user_information WHERE id=?",id))
            p @selected_users
        end
        matched_ids=db.execute("SELECT individual_id FROM relation_list INNER JOIN user_information ON relation_list.employer_id = user_information.id AND match_status_e=1 AND match_status_i=1")
        @matched_users = []
        matched_ids.each do |id|
            @matched_users.push(db.get_first_value("SELECT user FROM user_information WHERE id=?",id))
            p @matched_users
        end
    end

    slim(:"/dashboard")
end

get('/update') do
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    user_id=session[:user_id]
    @logged_user = db.execute("SELECT * FROM user_information WHERE id=?", user_id).first
    slim(:"/update_user")
end

post('/update_user') do
    db = SQLite3::Database.new("db/databas.db")
    user = params["user"]
    ind = params["ind"]
    emp = params["emp"]
    desc = params["desc"]
    type = params["type"]
    user_id = session[:user_id]

    db.execute("UPDATE user_information SET description = ?, type = ? WHERE id = ? ", [desc,type, user_id])
    redirect('/dashboard')
end

post('/logout') do
    session[:user_id] = nil
    redirect('/start')
end

post('/delete') do
    db = SQLite3::Database.new("db/databas.db")
    user_id = session[:user_id]

    #db.execute("DELETE FROM users FULL JOIN user_information ON users.id = user_information.id WHERE id=?",user_id)

    db.execute("DELETE FROM users WHERE id=?",user_id)
    db.execute("DELETE FROM user_information WHERE id=?",user_id)
    if session[:type] == "emp"
        db.execute("DELETE FROM relation_list WHERE employer_id=?",user_id)
    else
        db.execute("DELETE FROM relation_list WHERE individual_id=?",user_id)
    end
    session[:user_id] = nil
    redirect('/start')
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
    session[:selected_id] = id
    user_id = session[:user_id]
    db = SQLite3::Database.new("db/databas.db")
    @selected_user = db.get_first_value("SELECT user FROM users WHERE id = ?", id)
    @username=db.get_first_value("SELECT user FROM users WHERE id=?",user_id)
    slim(:"/index")
end

post('/hird/ignore') do
    db = SQLite3::Database.new("db/databas.db")
    id = session[:selected_id]
    login_id = session[:user_id].to_i
    #db.results_as_hash = true
    if session[:type] == "emp"
        db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_e) VALUES (?,?,?)",[id, login_id, 0])
        id_arr = db.execute("SELECT id FROM user_information WHERE type=?",["emp"]).flatten
    else
        db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_i) VALUES (?,?,?)",[login_id, id, 0])
        id_arr = db.execute("SELECT id FROM user_information WHERE type=?",["ind"]).flatten
    end
    redirect("/hird/#{generate_id(id_arr)}")
end

post('/hird/add') do
    db = SQLite3::Database.new("db/databas.db")
    id = session[:selected_id]
    db.results_as_hash = false
    p id
    login_id = session[:user_id]
    if db.get_first_value("SELECT type FROM user_information WHERE id = ?", login_id) == "emp"
        db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_e) VALUES (?,?,?)",[id, login_id, 1])
    elsif db.get_first_value("SELECT type FROM user_information WHERE id = ?", login_id) == "ind"
        db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_i) VALUES (?,?,?)",[login_id, id, 1])
    end
    #FIX THIS
    #if session[:type] == "emp"
    #    id_arr = db.execute("SELECT user_information.id FROM relation_list INNER JOIN relation_list ON user_information.id = relation_list.relation_id WHERE type=? AND match_status_i=?",["emp",nil]).flatten
    #else
    #    id_arr = db.execute("SELECT user_information.id FROM relation_list INNER JOIN relation_list ON user_information.id = relation_list.relation_id WHERE type=? AND match_status_e=?",["ind",nil]).flatten
    #end
    ##db.results_as_hash = false
    #redirect("/hird/#{generate_id(id_arr)}")
    #user = db.execute("SELECT user FROM individual WHERE id = ?", id)

    #ändra databas i framtiden
    
    #id_arr = db.execute("SELECT id FROM individual").flatten
    #redirect("/hird/#{generate_id(id_arr)}")
end

