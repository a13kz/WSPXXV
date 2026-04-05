
def get_selected_users(type,opposite_type,status_type,opposite_status_type,user_id)
    db = SQLite3::Database.new("db/databas.db")
    selected_ids=db.execute("SELECT #{opposite_type} FROM relation_list INNER JOIN user_information ON relation_list.#{type} = user_information.info_id WHERE #{opposite_status_type}=1 AND #{status_type} IS NULL AND user_information.info_id=?",user_id)
    p selected_ids
    selected_users = []
    selected_ids.each do |id|
        selected_users.push(db.get_first_value("SELECT user FROM user_information WHERE info_id=?",id))
    end
    return selected_users
end

def get_matched_users(type,opposite_type,status_type,opposite_status_type,user_id)
    db = SQLite3::Database.new("db/databas.db")
    selected_ids=db.execute("SELECT #{opposite_type} FROM relation_list INNER JOIN user_information ON relation_list.#{type} = user_information.info_id WHERE #{opposite_status_type}=1 AND #{status_type}=1 AND user_information.info_id=?",user_id)
    p selected_ids
    selected_users = []
    selected_ids.each do |id|
        selected_users.push(db.get_first_value("SELECT user FROM user_information WHERE info_id=?",id))
    end
    return selected_users
end

def connect_to_db(path)
    db = SQLite3::Database.new(path)
    db.results_as_hash = true
    return db
end

helpers do
    def generate_new_path(type,user_id)

        db=connect_to_db("db/databas.db")
        db.results_as_hash=false
        opp_type=get_opposite_type(type)
        type_id=get_type_id(type)
        opp_type_id=get_type_id(opp_type)
        match_status_type=get_status(type)
        arr = db.execute("SELECT info_id FROM user_information WHERE type=?",opp_type)
        sub_arr = db.execute("SELECT #{opp_type_id} FROM relation_list WHERE #{type_id}=? AND #{match_status_type} NOT NULL",user_id)
        available=arr-sub_arr
        available=available.flatten
        selected_id = available.sample
        if available.empty?
            p "no more users avalible"
            redirect("/hird/logged/user/dashboard")
        end
            redirect("/hird/logged/user/#{selected_id}")
        return
    end
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
    def get_id(user,path)
        db=connect_to_db(path)
        return db.get_first_value("SELECT info_id FROM user_information WHERE user=?",user)
    end
end

helpers do
    def check_login(user_id)
        if user_id == nil
            redirect('/hird')
        end
    end
end

helpers do
    def check_ownership(id,user_id,type)
        db=connect_to_db("db/databas.db")
        db.results_as_hash=false
        if type =="emp"
            ids=db.execute("SELECT individual_id FROM relation_list WHERE employer_id=? AND match_status_i=1",user_id).flatten
            p ids
            p id
            if ids.include?(id)
                return
            #redirect('/hird/logged/dashboard')
        else
            redirect('/hird/error')
        end
        else
            ids=db.execute("SELECT employer_id FROM relation_list WHERE individual_id=? AND match_status_i=1",user_id).flatten
            p ids
            p id
            if ids.include?(id)        
            return
            #redirect('/hird/logged/dashboard')
        else
            redirect('/hird/error')
        end
        end
    end
end

def get_user(id)
    db=connect_to_db("db/databas.db")
    result=db.execute("SELECT * FROM user_information WHERE info_id=?",id)
    return result
end

def ignore(type,id,login_id)
    db = SQLite3::Database.new("db/databas.db")
    if type == "emp"
        result=db.execute("SELECT employer_id FROM relation_list WHERE individual_id=?",id)
        if result.include?([login_id])
            db.execute("UPDATE relation_list SET match_status_e = ? WHERE individual_id = ? AND employer_id=?", [0,id,login_id])
        else
            db.execute("INSERT INTO relation_list (individual_id, employer_id, match_status_e) VALUES (?,?,?)",[id, login_id, 0])
        end
    else
        result=db.execute("SELECT individual_id FROM relation_list WHERE employer_id=?",id)
        if result.include?([login_id])
            db.execute("UPDATE relation_list SET match_status_i = ? WHERE employer_id = ? AND individual_id=? ", [0,id,login_id])
        else
            db.execute("INSERT INTO relation_list (employer_id, individual_id,match_status_i) VALUES (?,?,?)",[id,login_id, 0])
        end
    end
end

def add(type,id,login_id)
    db = SQLite3::Database.new("db/databas.db")
    if type == "emp"
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
    
end

def get_error_message(id)
    db = SQLite3::Database.new("db/databas.db")
    msg=db.get_first_value("SELECT message FROM error_messages WHERE error_id=?",id)
    return msg
end

def delete_user(user_id)
    db = SQLite3::Database.new("db/databas.db")
    db.execute("DELETE FROM users WHERE id=?",user_id)
    db.execute("DELETE FROM user_information WHERE info_id=?",user_id)
    db.execute("DELETE FROM relation_list WHERE employer_id=?",user_id)
    db.execute("DELETE FROM relation_list WHERE individual_id=?",user_id)
end

def check_password(user,pwd)
    db=connect_to_db("db/databas.db")
    result=db.execute("SELECT id,pwd_digest FROM users WHERE user=?",user)
    admin_result=db.execute("SELECT admin_key,pwd_digest FROM admins WHERE user=?",user)
    if result.empty? && admin_result.empty?
        redirect('/hird/error')
        return
    end
    if admin_result.empty?
        user_id = result.first["id"]
        pwd_digest = result.first["pwd_digest"]
        if BCrypt::Password.new(pwd_digest) == pwd
            session[:user_id] = user_id
            redirect("/hird/logged/user/dashboard")
        else
            redirect('/hird/error')
        end
    else
        admin_key = admin_result.first["admin_key"]
        admin_pwd_digest = admin_result.first["pwd_digest"]
        if BCrypt::Password.new(admin_pwd_digest) == pwd
            session[:admin_key] = admin_key
            redirect("/hird/logged/admin")
        else
        redirect('/hird/error')
        end
    end
end

def check_register(user,pwd,pwd_confirm,type,desc)
    db=connect_to_db("db/databas.db")
    result=db.execute("SELECT id FROM users WHERE user=?",user)
    if result.empty?
        if pwd==pwd_confirm
            pwd_digest=BCrypt::Password.create(pwd)
            db.execute("INSERT INTO users (user,pwd_digest) VALUES(?,?)",[user,pwd_digest])
            db.execute("INSERT INTO user_information (user,type,description) VALUES(?,?,?)",[user,type,desc])
            session[:user_id] = get_id(user,"db/databas.db")
            p get_id(user,"db/databas.db")
            redirect("/hird/logged/user/dashboard")
        else
            redirect('/hird/1/error')
        end
    else
        redirect('/hird/log')
    end
end

def get_user_info(user_id)
    db=connect_to_db("db/databas.db")
    arr=db.execute("SELECT (user,description,type) FROM user_information WHERE info_id=?",user_id)
    return arr
end

def edit_user(user_id)
    db=connect_to_db("db/databas.db")
    return db.execute("SELECT * FROM user_information WHERE info_id=?", user_id).first
end


def edit_selected_user(item_id,user_id)
    db=connect_to_db("db/databas.db")
    db.results_as_hash=false
    arr=db.execute("SELECT admin_id FROM admins").flatten
    p arr
    if arr.include?(user_id)
        db.results_as_hash=true
        return db.execute("SELECT * FROM user_information WHERE info_id=?", item_id).first
    end
end

def update_user(user_id,desc)
    db=connect_to_db("db/databas.db")
    db.execute("UPDATE user_information SET description = ? WHERE info_id = ? ", [desc, user_id])
end

def get_current_item(id)
    db=connect_to_db("db/databas.db")
    arr=db.execute("SELECT user,description FROM user_information WHERE info_id=?",id)
    return arr
end

def get_username(user_id)
    db=connect_to_db("db/databas.db")
    return db.get_first_value("SELECT user FROM user_information WHERE info_id=?",user_id)
end

def validate_password(pass)
    
end

def get_users
    db=connect_to_db("db/databas.db")
    return db.execute("SELECT * FROM user_information")
end

def autherization(user_id)
    db=connect_to_db("db/databas.db")

end