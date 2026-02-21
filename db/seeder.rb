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
end

def populate_tables(db)
  db.execute('INSERT INTO individual (user, description, CV) VALUES ("Alex", "Duktig, lojal, något annat","N/A")')
  db.execute('INSERT INTO employer (user, type, description) VALUES ("Hird", "mjukvaroutvecklare","det är en jättekul arbetsplats")')
end


seed!(db)





