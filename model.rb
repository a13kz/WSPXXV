

def test_model()
return "hej"
end

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
            redirect("/hird/logged/dashboard")
        end
        redirect("/hird/#{selected_id}")
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
        return db.get_first_value("SELECT id FROM user_information WHERE user=?",user)
    end
end

helpers do
  def check_login(user_id)
    if user_id ||= session[:user_id]
      redirect('/hird')
    end
  end
end