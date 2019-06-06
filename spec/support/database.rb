require "sqlite3"

ActiveRecord::Base.establish_connection({
  adapter: "sqlite3",
  database: ":memory:",
})

class CreateTables < ActiveRecord::Migration[4.2]
  def self.up
    create_table :organizations do |t|
      t.string :name
    end
    create_table :teams do |t|
      t.string :name
    end
    create_table :users do |t|
      t.string :nickname
      t.datetime :last_logined_at
      t.integer :team_id
      t.string :belong_type
      t.integer :belong_id
    end
  end
end

CreateTables.up
