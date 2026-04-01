require 'sqlite3'

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
  db.execute('DROP TABLE IF EXISTS relation_list')
 # db.execute('DROP TABLE IF EXISTS users')
end

def create_tables(db)
  #db.execute('CREATE TABLE user_information (
  #            id INTEGER PRIMARY KEY AUTOINCREMENT,
  #            user TEXT NOT NULL,
  #            type TEXT,
  #            description TEXT)')

  db.execute('CREATE TABLE relation_list (
              relation_id INTEGER PRIMARY KEY AUTOINCREMENT,
              individual_id INTEGER FOREIN KEY,
              match_status_i BOOLEAN FOREIN KEY, 
              employer_id INTEGER,
              match_status_e BOOLEAN)'
              )#

  #db.execute('CREATE TABLE users (
  #            id INTEGER PRIMARY KEY AUTOINCREMENT,
  #            user TEXT,
  #            pwd_digest TEXT)')
end

def populate_tables(db)
  #db.execute('INSERT INTO individual (user, description, CV) VALUES ("Alex", "Duktig, lojal, något annat","N/A")')
  #db.execute('INSERT INTO individual (user, description, CV) VALUES ("Balex", "Duktig, lojal, något annat","N/A")')
  #db.execute('INSERT INTO individual (user, description, CV) VALUES ("Bohre", "Duktig, lojal, något annat","N/A")')
  #db.execute('INSERT INTO individual (user, description, CV) VALUES ("Boris", "Duktig, lojal, något annat","N/A")')
  #db.execute('INSERT INTO employer (user, type, description) VALUES ("Hird", "mjukvaroutvecklare","det är en jättekul arbetsplats")')
  #db.execute('INSERT INTO relation_list (individual_id, match_status_i, employer_id, match_status_e) VALUES (1, 0,0,1)')
  #db.execute('INSERT INTO users (user, pwd) VALUES ("", "","")')
end


seed!(db)





