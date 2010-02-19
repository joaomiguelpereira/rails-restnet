class CreatePasswordRecoveries < ActiveRecord::Migration
  def self.up
    create_table :password_recoveries do |t|
      t.integer :user_id
      t.string :key
      t.timestamps
    end
  end
  
  def self.down
    drop_table :password_recoveries
  end
end
