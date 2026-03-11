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
  db.execute('DROP TABLE IF EXISTS individual')
  db.execute('DROP TABLE IF EXISTS employer')
  db.execute('DROP TABLE IF EXISTS relation_list')
  db.execute('DROP TABLE IF EXISTS store')
end

def create_tables(db)
  db.execute('CREATE TABLE individual (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user TEXT NOT NULL, 
              description TEXT,
              CV TEXT)')

  db.execute('CREATE TABLE employer (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              user TEXT NOT NULL, 
              type TEXT,
              description TEXT)')

  db.execute('CREATE TABLE relation_list (
              individual_id INTEGER,
              match_status_i BOOLEAN NOT NULL, 
              employer_id INTEGER,
              match_status_e BOOLEAN NOT NULL)')

  db.execute('CREATE TABLE store (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              users TEXT,
              type TEXT,
              pwd_digest TEXT)')
end

def populate_tables(db)
  db.execute('INSERT INTO individual (user, description, CV) VALUES ("Alex", "Duktig, lojal, något annat","N/A")')
  db.execute('INSERT INTO individual (user, description, CV) VALUES ("Balex", "Duktig, lojal, något annat","N/A")')
  db.execute('INSERT INTO individual (user, description, CV) VALUES ("Bohre", "Duktig, lojal, något annat","N/A")')
  db.execute('INSERT INTO individual (user, description, CV) VALUES ("Boris", "Duktig, lojal, något annat","N/A")')
  db.execute('INSERT INTO employer (user, type, description) VALUES ("Hird", "mjukvaroutvecklare","det är en jättekul arbetsplats")')
  db.execute('INSERT INTO relation_list (individual_id, match_status_i, employer_id, match_status_e) VALUES (1, 1,1,1)')
  db.execute('INSERT INTO store (users, pwd) VALUES ("", "","")')
end


seed!(db)





