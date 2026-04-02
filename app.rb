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

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
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
    
    db=connect_to_db("db/databas.db")
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
    
    db=connect_to_db("db/databas.db")
    
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

def get_selected_users(type,opposite_type,status_type,opposite_status_type,user_id)
    db = SQLite3::Database.new("db/databas.db")
    p type
  
    selected_ids=db.execute("SELECT #{opposite_type} FROM relation_list INNER JOIN user_information ON relation_list.#{type} = user_information.id WHERE #{opposite_status_type}=1 AND #{status_type} IS NULL AND user_information.id=?",user_id)
    p selected_ids
    selected_users = []
    selected_ids.each do |id|
        selected_users.push(db.get_first_value("SELECT user FROM user_information WHERE id=?",id))
    end
    return selected_users
end

get('/error') do
    time = Time.now()
    session[:old_time]
    slim(:"/error")
end

before('/dashboard') do
    p "this is before dashboard"
end

def get_opposite_type(type)
    if type == "emp"
        return "ind"
    else
        return "emp"
    end
end
def get_type_id(type)
    if type == "emp"
        return "employer_id"
    else
        return "individual_id"
    end
end

def get_status(type)
    if type == "emp"
        return "match_status_e"
    else
        return "match_status_i"
    end
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

    @selected_users=get_selected_users(get_type_id(@type),get_type_id(get_opposite_type(@type)),get_status(@type),get_status(get_opposite_type(@type)),user_id)
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
    db.execute("DELETE FROM relation_list WHERE employer_id=?",user_id)
    db.execute("DELETE FROM relation_list WHERE individual_id=?",user_id)
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

    if session[:type] == "emp"
        result=db.execute("SELECT employer_id FROM relation_list WHERE individual_id=?",id)
        p result
        if result.include?([login_id])
            p "matchad"
            db.execute("UPDATE relation_list SET match_status_e = ? WHERE individual_id = ? ", [0,id])
        else
            db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_e) VALUES (?,?,?)",[id, login_id, 0])
        end
    else
        result=db.execute("SELECT individual_id FROM relation_list WHERE employer_id=?",id)
        p result
        if result.include?([login_id])
            db.execute("UPDATE relation_list SET match_status_i = ?, WHERE employer_id = ? ", [0,id])
        else
        db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_i) VALUES (?,?,?)",[login_id, id, 0])
        end
    end
end

post('/hird/add') do
    db = SQLite3::Database.new("db/databas.db")
    id = session[:selected_id]
    db.results_as_hash = false
    p id
    login_id = session[:user_id]
    if session[:type] == "emp"
        result=db.execute("SELECT employer_id FROM relation_list WHERE individual_id=? AND match_status_i=1",id)
        p result
        if result.include?([login_id])
            p "matchad"
            db.execute("UPDATE relation_list SET match_status_e = ? WHERE individual_id = ? ", [1,id])
        else
            db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_e) VALUES (?,?,?)",[id, login_id, 1])
        end
    else
        result=db.execute("SELECT individual_id FROM relation_list WHERE employer_id=? AND match_status_e=1",id)
        p result
        if result.include?([login_id])
            p "matchad"
            db.execute("UPDATE relation_list SET match_status_i = ?, WHERE employer_id = ? ", [1,id])
        else
        db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_i) VALUES (?,?,?)",[login_id, id, 1])
        end
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

