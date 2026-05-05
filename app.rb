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

include Model

# Displays the signup page
#
get('/hird/signup') do
    slim(:"user/new")
end

# Displays an error message
#
# @param [Integer] :id the ID of the error message to display
#
# @see Model#get_error_message
get("/hird/error/:id") do
    id=params[:id]
    @error_msg=get_error_message(id)
    slim(:"/error")
end

# Generates a new user to swipe on based on the current user's type
# 
# @param [Integer] user_id, The ID of the selected user
# @param [String] type, The selected user's type
# @see Model#generate_new_path
post('/hird/logged/user/swipe') do
    login_id = session[:user_id]
    type = session[:type]
    generate_new_path(type,login_id)
end

# Validates registration form data before processing
#
# @param [Hash] params form data
# @option params [String] user the desired username
# @option params [String] pwd the desired password
# @option params [String] pwd_confirm the password confirmation
# @option params [String] type the type of user being registered
# @option params [String] desc the user's description
# @see Model#validate_password
# @see Model#validate_username
before('/hird/register') do
    if params["user"]==nil||params["pwd"]==nil||params["pwd_confirm"]==nil||params["type"]==nil|| desc = params["desc"]== nil
        redirect('/hird/error')
    end
    validate_password(params["pwd"])
    validate_username(params["user"])
end

# Processes a new user registration
#
# @param [Hash] params form data
# @option params [String] user the desired username
# @option params [String] pwd the desired password
# @option params [String] pwd_confirm the password confirmation
# @option params [String] type the type of user being registered
# @option params [String] desc the user's description
#
# @see Model#check_register
post('/hird/register') do
    user = params["user"]
    pwd = params["pwd"]
    pwd_confirm = params["pwd_confirm"]
    type = params["type"]
    desc = params["desc"]
    check_register(user,pwd,pwd_confirm,type,desc)
end

# Processes a login attempt
#
# @param [Hash] params form data
# @option params [String] user the username
# @option params [String] pwd the password
#
# @see Model#check_password
post('/hird/login') do
    session.clear
    user = params["user"]
    pwd = params["pwd"]
    check_password(user,pwd)
end


# Checks that the user is logged in before accessing user routes
#
# @see Model#check_login
before('/hird/logged/user/*') do
    check_login(session[:user_id])
end

# Checks that the admin is logged in before accessing admin routes
#
# @see Model#check_login
before('/hird/logged/admin/*') do
    check_login(session[:admin_key])
end

# Returns the opposite user type
#
# @param [String] type the current user type ('emp' or 'ind')
#
# @return [String] the opposite user type
def get_opposite_type(type)
    if type == "emp"
        return "ind"
    else
        return "emp"
    end
end

# Returns the type of id
#
# @param [String] type the user type ('emp' or 'ind')
#
# @return [String] the corresponding column name ('employer_id' or 'individual_id')
def get_type_id(type)
    if type == "emp"
        return "employer_id"
    else
        return "individual_id"
    end
end

# Returns the type of match status
#
# @param [String] type the user type ('emp' or 'ind')
#
# @return [String] the corresponding status column name ('match_status_e' or 'match_status_i')
def get_status(type)
    if type == "emp"
        return "match_status_e"
    else
        return "match_status_i"
    end
end

# Displays the user dashboard with matched and selected users
#
# @see Model#get_selected_users
# @see Model#get_matched_users
# @see Model#get_type_id
# @see Model#get_opposite_type
# @see Model#get_status
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
    slim(:"/user/start")
end

# Displays the edit page for the current user
#
# @see Model#edit_user
get('/hird/logged/user/edit') do
    user_id=session[:user_id]
    @logged_user=edit_user(user_id)
    slim(:"/user/edit")
end

# Logs in a regular user by storing their ID in the session
#
# @param [Integer] user_id the ID of the user to log in
#
def login_user(user_id)
    session[:user_id]=user_id
end

# Logs in an admin by storing their key in the session
#
# @param [String] admin_key the admin key to store in the session
#
def login_admin(admin_key)
    session[:admin_key]=admin_key
end

# Updates the current user's description
#
# @param [Integer] user_id the ID of the user to log in
# @param [Hash] params form data
# @option params [String] desc the new description
#
# @see Mode#update_user
post('/hird/logged/user/update') do
    desc = params["desc"]
    user_id = session[:user_id]

    update_user(user_id,desc)
    redirect('/hird/logged/user/dashboard')
end

# Updates a user's description as an admin
#
# @param [Integer] id the ID of the user to update
# @param [Hash] params form data
# @option params [String] desc the new description
#
# @see Model#update_user
post('/hird/logged/admin/:id/update') do
    desc = params["desc"]
    item_id = params[:id]

    update_user(item_id,desc)
    redirect('/hird/logged/admin/dashboard')
end

# Logs out the current user and clears the session
#
post('/hird/logged/logout') do
    session.clear
    redirect('/hird')
end

# Deletes the current user's account and clears the session
#
# @param [Integer] user_id the ID of the user
#
# @see Model#delete_user
post('/hird/logged/user/delete') do
    user_id = session[:user_id]
    delete_user(user_id)
    session.clear
    redirect('/hird')
end

# Displays the login page
#
get('/hird/log') do
    slim(:"/login")
end

# Displays the root/start page
#
get('/hird') do
    slim(:"/start")
end

# Ignores the currently selected user and generates a new path
#
# @param [Integer] selected_id the selected ID
# @param [String] type the type of the user
# @param [Integer] user_id the ID of the selected user
#
# @see Model#generate_new_path
# @see Model#ignore
# @see Model#generate_new_path
post('/hird/logged/user/ignore') do
    id = session[:selected_id]
    login_id = session[:user_id]
    type = session[:type]
    ignore(type,id,login_id)
    generate_new_path(type,login_id)
end

# Adds the currently selected user and generates a new path
#
# @param [Integer] selected_id the ID of the item to add
# @param [String] type the type of the user to add
# @param [Integer] user_id the ID of the user
# @see Model#add
# @see Model#generate_new_path
post('/hird/logged/user/add') do
    id = session[:selected_id]
    login_id = session[:user_id]
    type = session[:type]
    add(type,id,login_id)
    generate_new_path(type,login_id)
end

# Removes a matched user from the current user's matches
#
# @param [Integer] :id the ID of the item to remove
# @param [String] type the type of the user to remove
# @param [Integer] user_id the ID of the user
#
# @see Model#ignore
post('/hird/logged/user/:id/remove') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    ignore(type,item_id,user_id)
    redirect('/hird/logged/user/dashboard')
end

# Deletes a user as an admin
#
# @param [Integer] :id the ID of the user to delete
#
# @see Model#delete_user
post('/hird/logged/admin/:id/delete') do
    item_id = params[:id].to_i
    delete_user(item_id)
    redirect('/hird/logged/admin/dashboard')
end

# Adds a user from the dashboard view
#
# @param [Integer] :id the ID of the item to add
# @param [String] type the type of the user
# @param [Integer] user_id the ID of the user
#
# @see Model#add
post('/hird/logged/user/:id/add') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    add(type,item_id,user_id)
    redirect('/hird/logged/user/dashboard')
end

# Displays a matched user's profile
#
# @param [Integer] :id the ID of the item to view
# @param [String] type the type of the user to display
# @param [Integer] user_id the ID of the user to display
#
# @see Model#check_ownership
get('/hird/logged/user/:id/read') do
    item_id = params[:id].to_i
    type=session[:type]
    user_id=session[:user_id]
    check_ownership(item_id,user_id,type)
    @selected_user=get_user(item_id)
    slim(:"/user/read")
end

# Displays the admin dashboard with all users
# @param [Integer] user_id the ID of the user
#
get('/hird/logged/admin/dashboard') do
    user_id = session[:user_id]
    @users=get_users
    slim(:"/user/index")
end

# Displays a user's profile for swiping
#
# @param [Integer] :id the ID of the user to display
# @param [Integer] selected_id the ID of the selected user
# @param [Hash] params form data
# @option params [String] user the desired username
# @option params [String] desc the user's description
# @see Model#get_current_item
# @see Model#get_username
get('/hird/logged/user/:id') do
    id = params[:id].to_i
    session[:selected_id] = id
    user_id = session[:user_id]
    arr=get_current_item(id)
    @selected_user = arr.first["user"]
    @description = arr.first["description"]
    @username=get_username(user_id)
    slim(:"/user/main")
end

# Displays the edit page for a user as an admin
#
# @param [Integer] :id the ID of the user to edit
# @param [String] admin_key the admin key
#
# @see Model#edit_selected_user
get('/hird/logged/admin/:id/edit') do
    item_id=params[:id].to_i
    admin_key=session[:admin_key]
    @selected_user=edit_selected_user(item_id,admin_key)
    slim(:"/admin/edit")
end

# Displays the chat page for a user
#
# @param [Integer] :id the ID of the user to chat with
#
get('/hird/logged/user/:id/chat') do
    slim(:"/user/chat")
end
