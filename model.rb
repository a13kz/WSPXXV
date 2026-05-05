module Model
    require 'date'
    require 'time'
    
    # Retrieves users from the opposite party where with an active matching status and the users is nil (pending requests).
    #
    # @params [String] type the current user's role in the relation_list
    # @params [String] opposite_type the opposite role from the current user
    # @params [String] status_type the current user's type of status
    # @params [String] opposite_status_type the current user's opposite type of status
    # @params [Integer] user_id the ID of the current user
    #
    # @return [Array<String>] a list of users whom have sent a request to the current user but not yet received a response

    def get_selected_users(type,opposite_type,status_type,opposite_status_type,user_id)
        db = SQLite3::Database.new("db/databas.db")
        selected_ids=db.execute("SELECT #{opposite_type} FROM relation_list INNER JOIN users ON relation_list.#{type} = users.id WHERE #{opposite_status_type}=1 AND #{status_type} IS NULL AND users.id=?",user_id)
        p selected_ids
        selected_users = []
        selected_ids.each do |id|
            selected_users.push(db.get_first_value("SELECT user FROM users WHERE id=?",id))
        end
        return selected_users
    end

    # Retrieves users in which both parties have an active status in the relationship (mutual matches).
    #
    # @params [String] type the current user's role in the relation_list
    # @params [String] opposite_type the opposite role from the current user
    # @params [String] status_type the current user's type of status
    # @params [String] opposite_status_type the current user's opposite type of status
    # @param [Integer] user_id the ID of the current user
    #
    # @return [Array<String>] a list of usernames who have mutually matched with the current user
    def get_matched_users(type,opposite_type,status_type,opposite_status_type,user_id)
        db = SQLite3::Database.new("db/databas.db")
        selected_ids=db.execute("SELECT #{opposite_type} FROM relation_list INNER JOIN users ON relation_list.#{type} = users.id WHERE #{opposite_status_type}=1 AND #{status_type}=1 AND users.id=?",user_id)
        p selected_ids
        selected_users = []
        selected_ids.each do |id|
            selected_users.push(db.get_first_value("SELECT user FROM users WHERE id=?",id))
        end
        return selected_users
    end

    # Connects to a SQLite3 database and returns the connection with results as hash.
    #
    # @param [String] path path to the database
    #
    # @return [SQLite3::Database] database connection

    def connect_to_db(path)
        db = SQLite3::Database.new(path)
        db.results_as_hash = true
        return db
    end

    # Generates new path by selecting a random available user of the opposite type.
    #
    # @param [String] type the type of the current user
    # @param [Integer] user_id the ID of the current user
    #
    # @return [void] redirects to the selected user's page or dashboard if no users are available
    def generate_new_path(type,user_id)
        db=connect_to_db("db/databas.db")
        db.results_as_hash=false
        opp_type=get_opposite_type(type)
        type_id=get_type_id(type)
        opp_type_id=get_type_id(opp_type)
        match_status_type=get_status(type)
        arr = db.execute("SELECT id FROM users WHERE type=?",opp_type)
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

    # Validates usernames against a set of invalid characters and length restrictions.
    #
    # @param [String] user the username to validate
    #
    # @return [void] redirects to error page if username is invalid

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

    # Retrieves the ID of a user from the database by username.
    #
    # @param [String] user the selected user's username
    # @param [String] path the path to the database
    #
    # @return [Integer] the ID of the user

    def get_id(user,path)
        db=connect_to_db(path)
        return db.get_first_value("SELECT id FROM users WHERE user=?",user)
    end

    # Checks whether the user is logged in and redirects them if not.
    #
    # @param [Integer] user_id the ID of the current user, or nil if not logged in
    #
    # @return [void] redirects to start if user is not logged in
    def check_login(user_id)
        if user_id == nil
            redirect('/hird')
        end
    end

    # Checks whether the current user has ownership/access to a selected user's profile.
    #
    # @param [Integer] id the ID of the profile to check access for
    # @param [Integer] user_id the ID of the current user
    # @param [String] type the type of the current user
    #
    # @return [void] redirects to error page if user does not have access
    def check_ownership(id,user_id,type)
        db=connect_to_db("db/databas.db")
        db.results_as_hash=false
        if type =="emp"
            ids=db.execute("SELECT individual_id FROM relation_list WHERE employer_id=? AND match_status_i=1",user_id).flatten
            p ids
            p id
            if ids.include?(id)
                return
        else
            redirect('/hird/error')
        end
        else
            ids=db.execute("SELECT employer_id FROM relation_list WHERE individual_id=? AND match_status_i=1",user_id).flatten
            if ids.include?(id)        
            return
        else
            redirect('/hird/error')
        end
        end
    end

    # Retrieves users from database by id.
    #
    # @param [Integer] id the id of the selected user
    # 
    # @return [Array<Hash>] the users matching the given id
    def get_user(id)
        db=connect_to_db("db/databas.db")
        result=db.execute("SELECT * FROM users WHERE id=?",id)
        return result
    end

    # Registers an ignore action between two users in the relation_list.
    #
    # @param [String] type the current user's type
    # @param [Integer] id the ID of the user being ignored
    # @param [Integer] login_id the ID of the current user
    #
    # @return [void]

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

    # Registers an add action between two users in the relation_list.
    #
    # @param [String] type the current user's type
    # @param [Integer] id the ID of the user being added
    # @param [Integer] login_id the ID of the current user
    #
    # @return [void]
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
    # Retrieves an error message from the database by error ID.
    #
    # @param [Integer] id the ID of the error message selected to be retrived
    #
    # @return [String] the error message corresponding to the selected ID
    def get_error_message(id)
        db = SQLite3::Database.new("db/databas.db")
        msg=db.get_first_value("SELECT message FROM error_messages WHERE error_id=?",id)
        return msg
    end

    # Deletes a user and their associated relations from the database
    #
    # @param [Integer] user_id the ID of the user to be deleted
    #
    # @return [void]
    def delete_user(user_id)
        db = SQLite3::Database.new("db/databas.db")
        db.execute("DELETE FROM users WHERE id=?",user_id)
        db.execute("DELETE FROM relation_list WHERE employer_id=?",user_id)
        db.execute("DELETE FROM relation_list WHERE individual_id=?",user_id)
    end

    # Records failed login attempts and bans the user if the maximum amount of attempts have been exceeded
    #
    # @param [Integer] user_id the ID of the user who failed to log in
    #
    # @return [void]
    def failed_attempts(user_id)
        db=connect_to_db("db/databas.db")
        d = Time.now.to_s
        max_attempts=5
        attempts=db.get_first_value("SELECT failed_attempts FROM users WHERE id=?",user_id)
        if attempts==0
        else
            last_time=db.get_first_value("SELECT last_failed FROM users WHERE id=?",user_id)
            last_time=Time.parse(last_time)
        end
        status=0
        if attempts >= max_attempts
            status=1
        end
        db.execute("UPDATE users SET last_failed=?,failed_attempts=?,status=? WHERE id=?",[d,attempts+1,status,user_id])
    end

    # Checks whether a banned user's ban period has expired and unbans them if so.
    #
    # @param [Integer] user_id the ID of the user to check
    #
    # @return [Boolean] true if the period is over, false if the ban is still active
    def unban(user_id)
        db=connect_to_db("db/databas.db")
        d = Time.now
        last_time=db.get_first_value("SELECT last_failed FROM users WHERE id=?",user_id)
        last_time=Time.parse(last_time)
        if last_time+5*60<d
            p "time"
            db.execute("UPDATE users SET last_failed=?,failed_attempts=?,status=? WHERE id=?",["",0,0,user_id])
            return true
        else
            return false
        end
    end

    # Validates login credentials and redirects to the appropriate dashboard on success.
    #
    # @param [String] user the username of the user attempting to log in
    # @param [String] pwd the password to verify
    #
    # @return [void] redirects user to user or admin dashboard on success, error page on failure

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
            stat=db.get_first_value("SELECT status FROM users WHERE id=?",user_id)
            if stat==1
                unban(user_id)
                redirect("/error")
            end
            if BCrypt::Password.new(pwd_digest) == pwd
                login_user(user_id)
                redirect("/hird/logged/user/dashboard")
            else
                p stat
                if stat==0
                    failed_attempts(user_id)
                    redirect("/hird/log")
                else
                    if unban(user_id)
                        redirect("/hird/log")
                    else
                        redirect("/error")
                    end
                    
                end
            end
        else
            admin_key = admin_result.first["admin_key"]
            admin_pwd_digest = admin_result.first["pwd_digest"]
            if BCrypt::Password.new(admin_pwd_digest) == pwd
                login_user(admin_key)
                redirect("/hird/logged/admin/dashboard")
            else
                redirect('/hird/error')
            end
        end
    end

    # Validates and processes a new user registration.
    #
    # @param [String] user the desired username
    # @param [String] pwd the desired password
    # @param [String] pwd_confirm the password confirmation
    # @param [String] type the type of user being registered
    # @param [String] desc the user's description
    #
    # @return [void] redirects to dashboard on success, error page on failure

    def check_register(user,pwd,pwd_confirm,type,desc)
        db=connect_to_db("db/databas.db")
        result=db.execute("SELECT id FROM users WHERE user=?",user)
        if result.empty?
            if pwd==pwd_confirm
                pwd_digest=BCrypt::Password.create(pwd)
                db.execute("INSERT INTO users (user,pwd_digest,type,description) VALUES(?,?,?,?)",[user,pwd_digest,type,desc])
                login_user(get_id(user,"db/databas.db"))
                #p get_id(user,"db/databas.db")
                redirect("/hird/logged/user/dashboard")
            else
                redirect('/hird/1/error')
            end
        else
            redirect('/hird/log')
        end
    end

    # Retrieves basic info (username, description, type) for a given user.
    #
    # @param [Integer] user_id the ID of the user
    #
    # @return [Array<Hash>] the user's info

    def get_user_info(user_id)
        db=connect_to_db("db/databas.db")
        arr=db.execute("SELECT (user,description,type) FROM users WHERE id=?",user_id)
        return arr
    end

    # Retrieves all fields for a given user with the purpose of editing them
    #
    # @param [Integer] user_id the ID of the user to edit
    #
    # @return [Hash] the user info

    def edit_user(user_id)
        db=connect_to_db("db/databas.db")
        return db.execute("SELECT * FROM users WHERE id=?", user_id).first
    end
    
    # Retrieves user information for admin editing purposes, if the admin key is valid.
    #
    # @param [Integer] item_id the ID of the user to edit
    # @param [String] admin_key the admin key to validate
    #
    # @return [Hash, nil] the user info if the admin key is valid, nil otherwise

    def edit_selected_user(item_id,admin_key)
        db=connect_to_db("db/databas.db")
        db.results_as_hash=false
        arr=db.execute("SELECT admin_key FROM admins").flatten
        p arr
        if arr.include?(admin_key)
            db.results_as_hash=true
            return db.execute("SELECT * FROM users WHERE id=?", item_id).first
        end
    end

    # Updates the description of a given user.
    #
    # @param [Integer] user_id the ID of the user to update
    # @param [String] desc the new description
    #
    # @return [void]
    def update_user(user_id,desc)
        db=connect_to_db("db/databas.db")
        db.execute("UPDATE users SET description = ? WHERE id = ? ", [desc, user_id])
    end

    # Retrieves the username and description for a given user.
    #
    # @param [Integer] id the ID of the user
    #
    # @return [Array<Hash>] the username and description of the user
    def get_current_item(id)
        db=connect_to_db("db/databas.db")
        arr=db.execute("SELECT user,description FROM users WHERE id=?",id)
        return arr
    end

    # Retrieves the username of a given user based on ID.
    #
    # @param [Integer] user_id the ID of the user
    #
    # @return [String] the username of the user
    def get_username(user_id)
        db=connect_to_db("db/databas.db")
        return db.get_first_value("SELECT user FROM users WHERE id=?",user_id)
    end

    # Retrieves all users from the database.
    #
    # @return [Array<Hash>] all users
    def get_users
        db=connect_to_db("db/databas.db")
        return db.execute("SELECT * FROM user")
    end
end