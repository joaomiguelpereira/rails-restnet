class CreatePersistentSessions < ActiveRecord::Migration
  def self.up
    create_table :persistent_sessions do |t|
      t.integer :user_id
      t.string :key
      t.index :user_id
      t.timestamps
    end
  end

  def self.down
    drop_table :persistent_sessions
  end
end
