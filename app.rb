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

get('/hird/signup') do
    slim(:"/new_user")
end

get("/hird/error/:id") do
    id=params[:id]
    @error_msg=get_error_message(id)
    slim(:"/error")
end



post('/hird/logged/user/swipe') do
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
    check_register(user,pwd,pwd_confirm,type,desc)
end

post('/hird/login') do
    session.clear
    user = params["user"]
    pwd = params["pwd"]
    check_password(user,pwd)
end

before('/hird/logged/user/*') do
    check_login(session[:user_id])
end
before('/hird/logged/admin/*') do
    check_login(session[:admin_key])
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



get('/hird/logged/user/dashboard') do
    user_id = session[:user_id]
    arr=get_user(user_id)
    @username=arr.first["user"]
    @desc=arr.first["description"]
    @type=arr.first["type"]
    session[:type] = @type
    @selected_users=get_selected_users(get_type_id(@type),get_type_id(get_opposite_type(@type)),get_status(@type),get_status(get_opposite_type(@type)),user_id)
    @matched_users=get_matched_users(get_type_id(@type),get_type_id(get_opposite_type(@type)),get_status(@type),get_status(get_opposite_type(@type)),user_id)
    p @selected_users
    slim(:"/dashboard")
end

get('/hird/logged/user/edit') do
    user_id=session[:user_id]
    @selected_user=edit_user(user_id)
    slim(:"/update_user")
end



post('/hird/logged/user/update') do
    desc = params["desc"]
    user_id = session[:user_id]

    update_user(user_id,desc)
    redirect('/hird/logged/user/dashboard')
end
post('/hird/logged/admin/:id/update') do
    desc = params["desc"]
    item_id = params[:id]

    update_user(item_id,desc)
    redirect('/hird/logged/admin')
end

post('/hird/logged/user/logout') do
    session.clear
    redirect('/hird')
end

post('/hird/logged/user/delete') do
    user_id = session[:user_id]
    delete_user(user_id)
    session.clear
    redirect('/hird')
end


get('/hird/log') do
    slim(:"/login")
end

get('/hird') do
    slim(:"/start")
end


post('/hird/logged/user/ignore') do
    id = session[:selected_id]
    login_id = session[:user_id]
    type = session[:type]
    ignore(type,id,login_id)
    generate_new_path(type,login_id)
end

# fixa med DRY sen
post('/hird/logged/user/add') do
    id = session[:selected_id]
    login_id = session[:user_id]
    type = session[:type]
    add(type,id,login_id)
    generate_new_path(type,login_id)
end

post('/hird/logged/user/:id/remove') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    ignore(type,item_id,user_id)
    redirect('/hird/logged/user/dashboard')
end

post('/hird/logged/admin/:id/delete') do
    item_id = params[:id].to_i
    delete_user(item_id)
    redirect('/hird/logged/admin')
end
post('/hird/logged/user/:id/add') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    add(type,item_id,user_id)
    redirect('/hird/logged/user/dashboard')
end

get('/hird/logged/user/:id/read') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    check_ownership(item_id,user_id,type)
    @selected_user=get_user(item_id)
    slim(:"/read")
end

get('/hird/logged/admin') do
    user_id = session[:user_id]
    @users=get_users
    slim(:"/admin_dash")
end

get('/hird/logged/user/:id') do
    id = params[:id].to_i
    session[:selected_id] = id
    user_id = session[:user_id]
    arr=get_current_item(id)
    @selected_user = arr.first["user"]
    @description = arr.first["description"]
    @username=get_username(user_id)
    slim(:"/index")
end
get('/hird/logged/admin/:id/edit') do
    item_id=params[:id].to_i
    user_id=session[:user_id]
    p edit_selected_user(item_id,user_id)
    p item_id
    @selected_user=edit_selected_user(item_id,user_id)
    slim(:"/update_item")
end

