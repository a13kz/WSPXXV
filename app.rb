require 'sinatra'
require 'slim'
require 'byebug'
require 'sqlite3'
require 'sinatra/reloader'
require 'bcrypt'
require 'sinatra/flash'
also_reload 'model'
enable :sessions
require_relative './model.rb'




def validate_password(pass)
    
end






get('/hird/signup') do
    slim(:"/new_user")
end

get("/hird/error/:id") do
    id=params[:id]
    @error_msg=get_error_message(id)
    slim(:"/error")
end



post('/hird/logged/swipe') do
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
            p get_id(user,"db/databas.db")
            redirect("/hird/logged/dashboard")
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
        redirect("/hird/logged/dashboard")
    else
        redirect('/hird/error')
    end

end

before('/hird/login') do

end
@username = nil

before('/hird/logged/:id*') do
    check_login(session[:user_id])
end


get('hird/:id/error') do
    time = Time.now()
    error_id = params[:id]
    session[:old_time]
    slim(:"/error")
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



get('/hird/logged/dashboard') do
    p test_model()
    if session[:user_id] == nil
        redirect('/hird')
    end
    db = SQLite3::Database.new("db/databas.db")
    user_id = session[:user_id]
    @username=db.get_first_value("SELECT user FROM user_information WHERE info_id=?",user_id)
    @desc=db.get_first_value("SELECT description FROM user_information WHERE info_id=?",user_id)
    @type=db.get_first_value("SELECT type FROM user_information WHERE info_id=?",user_id)
    session[:type] = @type
    @selected_users=get_selected_users(get_type_id(@type),get_type_id(get_opposite_type(@type)),get_status(@type),get_status(get_opposite_type(@type)),user_id)
    @matched_users=get_matched_users(get_type_id(@type),get_type_id(get_opposite_type(@type)),get_status(@type),get_status(get_opposite_type(@type)),user_id)
    p @selected_users
    slim(:"/dashboard")
end

get('/hird/logged/edit') do
    db = SQLite3::Database.new("db/databas.db")
    db.results_as_hash = true
    user_id=session[:user_id]
    @logged_user = db.execute("SELECT * FROM user_information WHERE info_id=?", user_id).first
    slim(:"/update_user")
end

post('/hird/logged/update') do
    db = SQLite3::Database.new("db/databas.db")
    user = params["user"]
    ind = params["ind"]
    emp = params["emp"]
    desc = params["desc"]
    type = params["type"]
    user_id = session[:user_id]

    db.execute("UPDATE user_information SET description = ? WHERE info_id = ? ", [desc, user_id])
    redirect('/hird/logged/dashboard')
end

post('/hird/logged/logout') do
    session.clear
    redirect('/hird')
end

post('/hird/logged/delete') do
    db = SQLite3::Database.new("db/databas.db")
    user_id = session[:user_id]
    db.execute("DELETE FROM users WHERE id=?",user_id)
    db.execute("DELETE FROM user_information WHERE info_id=?",user_id)
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


get('/hird/logged/:id') do
    id = params[:id].to_i
    session[:selected_id] = id
    user_id = session[:user_id]
    db = SQLite3::Database.new("db/databas.db")
    @selected_user = db.get_first_value("SELECT user FROM user_information WHERE info_id= ?", id)
    @description = db.get_first_value("SELECT description FROM user_information WHERE info_id=?", id)
    @username=db.get_first_value("SELECT user FROM users WHERE id=?",user_id)
    slim(:"/index")
end

post('/hird/logged/ignore') do

    id = session[:selected_id]
    login_id = session[:user_id]
    type = session[:type]
    ignore(type,id,login_id)
    generate_new_path(type,login_id)
end

# fixa med DRY sen
post('/hird/logged/add') do
    
    id = session[:selected_id]
    login_id = session[:user_id]
    type = session[:type]
    add(type,id,login_id)
    generate_new_path(type,login_id)
end

post('/hird/logged/:id/remove') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    ignore(type,item_id,user_id)
    redirect('/hird/logged/dashboard')
end

post('/hird/logged/:id/add') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    add(type,item_id,user_id)
    redirect('/hird/logged/dashboard')
end

get('/hird/logged/:id/read') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    check_ownership(item_id,user_id,type)
    @selected_user=get_user(item_id)
    slim(:"/read")
end