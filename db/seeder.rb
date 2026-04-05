require 'sqlite3'
require 'bcrypt'
db = SQLite3::Database.new("databas.db")


def seed!(db)
  puts "Using db file: db/todos.db"
  puts "🧹 Dropping old tables..."
  drop_tables(db)
  puts "🧱 Creating tables..."
  create_tables(db)
  puts "🍎 Populating tables..."
  populate_tables(db)
  puts "✅ Done seeding the database!"
end

def drop_tables(db)
  #db.execute('DROP TABLE IF EXISTS user_information')
  #db.execute('DROP TABLE IF EXISTS relation_list')
  #db.execute('DROP TABLE IF EXISTS error_messages')
  db.execute('DROP TABLE IF EXISTS admins')
  #db.execute('DROP TABLE IF EXISTS users')
end

def create_tables(db)
  #db.execute('CREATE TABLE user_information (
  #            info_id INTEGER PRIMARY KEY AUTOINCREMENT,
  #            user TEXT NOT NULL,
  #            type TEXT,
  #            description TEXT)')
#
  #db.execute('CREATE TABLE relation_list (
  #            individual_id INTEGER FOREIN KEY,
  #            match_status_i BOOLEAN FOREIN KEY, 
  #            employer_id INTEGER,
  #            match_status_e BOOLEAN)'
  #            )
  #db.execute('CREATE TABLE error_messages (
  #            error_id INTEGER PRIMARY KEY AUTOINCREMENT,
  #            message TEXT)')
              
  db.execute('CREATE TABLE admins (
              admin_key TEXT PRIMARY KEY,
              user TEXT,
              pwd_digest TEXT)')

  #db.execute('CREATE TABLE users (
  #            id INTEGER PRIMARY KEY AUTOINCREMENT,
  #            user TEXT,
  #            pwd_digest TEXT)')
end

def populate_tables(db)
  #db.execute('INSERT INTO error_messages (message) VALUES("invalid characters")')
  
  #db.execute("INSERT INTO user_information (user,type,description) VALUES(?,?,?)",[user,type,desc])
end


seed!(db)





