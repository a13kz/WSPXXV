require 'sinatra'
require 'slim'
require 'byebug'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'
require_relative './model.rb'

enable :sessions

def validate_password(pass)
    
end

def validate_username(user)
    invalid_chars=["@","#","!","'","¤","$"," "]
    invalid_chars.each do |c|
        p "hej"
        if user.include?(c)
            flash[:error] = "invalid character"
            redirect("hird/error")
        end
    end
    if user.length > 20
        redirect("hird/error")
    end
end

helpers do
    def generate_new_path(type,user_id)

        db=connect_to_db("db/databas.db")
        db.results_as_hash=false
        opp_type=get_opposite_type(type)
        type_id=get_type_id(type)
        opp_type_id=get_type_id(opp_type)
        match_status_type=get_status(type)
        arr = db.execute("SELECT id FROM user_information WHERE type=?",opp_type)
        sub_arr = db.execute("SELECT #{opp_type_id} FROM relation_list WHERE #{type_id}=? AND #{match_status_type} NOT NULL",user_id)
        available=arr-sub_arr
        available=available.flatten
        selected_id = available.sample
        if available.empty?
            p "no more users avalible"
            redirect("/hird/dashboard")
        end
        redirect("/hird/#{selected_id}")
        return
    end
end

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end


get('/hird/signup') do
    slim(:"/new_user")
end

get("/hird/error") do
    slim(:"/error")
end

helpers do
    def get_id(user,path)
        db=connect_to_db(path)
        return db.get_first_value("SELECT id FROM user_information WHERE user=?",user)
    end
end

post('/hird/swipe') do
    login_id = session[:user_id]
    type = session[:type]
    generate_new_path(type,login_id)
end

before('/hird/register') do
    if params["user"]==nil||params["pwd"]==nil||params["pwd_confirm"]==nil||params["type"]==nil|| desc = params["desc"]== nil
        redirect('/hird/error')
    end
    validate_password(params["pwd"])
    validate_username(params["user"])
end



post('/hird/register') do
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
            session[:user_id] = get_id(user,"db/databas.db")
            redirect("/hird/dashboard")
        else
            redirect('/hird/1/error')
        end
    else
        redirect('/hird/login')
    end
    
end

post('/hird/login') do
    user = params["user"]
    pwd = params["pwd"]
    
    db=connect_to_db("db/databas.db")
    
    result=db.execute("SELECT id,pwd_digest FROM users WHERE user=?",user)
    #p result
    if result.empty?
        redirect('/hird/error')
        return
    end
    
    user_id = result.first["id"]
    pwd_digest = result.first["pwd_digest"]
    
    if BCrypt::Password.new(pwd_digest) == pwd
        
        session[:user_id] = user_id
        redirect("/hird/dashboard")
    else
        redirect('/hird/error')
    end

end

before('/hird/login') do

end
@username = nil

def get_selected_users(type,opposite_type,status_type,opposite_status_type,user_id)
    db = SQLite3::Database.new("db/databas.db")
    selected_ids=db.execute("SELECT #{opposite_type} FROM relation_list INNER JOIN user_information ON relation_list.#{type} = user_information.id WHERE #{opposite_status_type}=1 AND #{status_type} IS NULL AND user_information.id=?",user_id)
    p selected_ids
    selected_users = []
    selected_ids.each do |id|
        selected_users.push(db.get_first_value("SELECT user FROM user_information WHERE id=?",id))
    end
    return selected_users
end

def get_matched_users(type,opposite_type,status_type,opposite_status_type,user_id)
    db = SQLite3::Database.new("db/databas.db")
    selected_ids=db.execute("SELECT #{opposite_type} FROM relation_list INNER JOIN user_information ON relation_list.#{type} = user_information.id WHERE #{opposite_status_type}=1 AND #{status_type}=1 AND user_information.id=?",user_id)
    p selected_ids
    selected_users = []
    selected_ids.each do |id|
        selected_users.push(db.get_first_value("SELECT user FROM user_information WHERE id=?",id))
    end
    return selected_users
end

get('hird/:id/error') do
    time = Time.now()
    error_id = params[:id]
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



get('/hird/dashboard') do
    if session[:user_id] == nil
        redirect('/hird')
    end
    db = SQLite3::Database.new("db/databas.db")
    user_id = session[:user_id]
    @username=db.get_first_value("SELECT user FROM users WHERE id=?",user_id)
    @desc=db.get_first_value("SELECT description FROM user_information WHERE id=?",user_id)
    @type=db.get_first_value("SELECT type FROM user_information WHERE id=?",user_id)
    session[:type] = @type
    @selected_users=get_selected_users(get_type_id(@type),get_type_id(get_opposite_type(@type)),get_status(@type),get_status(get_opposite_type(@type)),user_id)
    @matched_users=get_matched_users(get_type_id(@type),get_type_id(get_opposite_type(@type)),get_status(@type),get_status(get_opposite_type(@type)),user_id)
    p @selected_users
    slim(:"/dashboard")
end

get('/hird/edit') do
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    user_id=session[:user_id]
    @logged_user = db.execute("SELECT * FROM user_information WHERE id=?", user_id).first
    slim(:"/update_user")
end

post('/hird/update') do
    db = SQLite3::Database.new("db/databas.db")
    user = params["user"]
    ind = params["ind"]
    emp = params["emp"]
    desc = params["desc"]
    type = params["type"]
    user_id = session[:user_id]

    db.execute("UPDATE user_information SET description = ? WHERE id = ? ", [desc, user_id])
    redirect('/hird/dashboard')
end

post('/hird/logout') do
    session.clear
    redirect('/hird')
end

post('/hird/delete') do
    db = SQLite3::Database.new("db/databas.db")
    user_id = session[:user_id]
    db.execute("DELETE FROM users WHERE id=?",user_id)
    db.execute("DELETE FROM user_information WHERE id=?",user_id)
    db.execute("DELETE FROM relation_list WHERE employer_id=?",user_id)
    db.execute("DELETE FROM relation_list WHERE individual_id=?",user_id)
    session.clear
    redirect('/hird')
end


get('/hird/log') do
    slim(:"/login")
end

get('/hird') do
    slim(:"/start")
end


get('/hird/:id') do
    id = params[:id].to_i
    session[:selected_id] = id
    user_id = session[:user_id]
    db = SQLite3::Database.new("db/databas.db")
    @selected_user = db.get_first_value("SELECT user FROM user_information WHERE id = ?", id)
    @description = db.get_first_value("SELECT description FROM user_information WHERE id = ?", id)
    @username=db.get_first_value("SELECT user FROM users WHERE id=?",user_id)
    slim(:"/index")
end

post('/hird/ignore') do
    db = SQLite3::Database.new("db/databas.db")
    id = session[:selected_id]
    login_id = session[:user_id]

    if session[:type] == "emp"
        result=db.execute("SELECT employer_id FROM relation_list WHERE individual_id=?",id)
        if result.include?([login_id])
            db.execute("UPDATE relation_list SET match_status_e = ? WHERE individual_id = ? ", [0,id])
        else
            db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_e) VALUES (?,?,?)",[id, login_id, 0])
        end
    else
        result=db.execute("SELECT individual_id FROM relation_list WHERE employer_id=?",id)
        if result.include?([login_id])
            db.execute("UPDATE relation_list SET match_status_i = ? WHERE employer_id = ? ", [0,id])
        else
            db.execute("INSERT INTO relation_list (employer_id, individual_id,match_status_i) VALUES (?,?,?)",[id,login_id, 0])
        end
    end
    type = session[:type]
    generate_new_path(type,login_id)
end

# fixa med DRY sen
post('/hird/add') do
    db = SQLite3::Database.new("db/databas.db")
    id = session[:selected_id]
    db.results_as_hash = false
    login_id = session[:user_id]
    if session[:type] == "emp"
        result=db.execute("SELECT employer_id FROM relation_list WHERE individual_id=? AND match_status_i=1",id)
        p result
        if result.include?([login_id])
            p "matchad"
            db.execute("UPDATE relation_list SET match_status_e=? WHERE individual_id=? AND employer_id=? ", [1,id,login_id])
        else
            db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_e) VALUES (?,?,?)",[id, login_id, 1])
        end
    else
        result=db.execute("SELECT individual_id FROM relation_list WHERE employer_id=? AND match_status_e=1",id)
        p result
        if result.include?([login_id])
            p "matchad"
            db.execute("UPDATE relation_list SET match_status_i = ? WHERE employer_id = ? AND individual_id=?", [1,id,login_id])
        else
        db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_i) VALUES (?,?,?)",[login_id, id, 1])
        end
    end
    type = session[:type]
    generate_new_path(type,login_id)
end

