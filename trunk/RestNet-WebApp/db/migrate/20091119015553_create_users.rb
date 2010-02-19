class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :handle
      t.string :hashed_password
      t.string :salt
      t.string :first_name
      t.string :last_name
      t.string :email
      t.string :activation_key
      t.boolean :active, :default=>false
      t.boolean :admin, :default=>false
      t.integer :fb_uid, :default=>0
      
      t.timestamps
    end
  end
  
  def self.down
    drop_table :users
  end
end
