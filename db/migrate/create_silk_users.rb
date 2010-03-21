class CreateSilkUsers < ActiveRecord::Migration
  def self.up
    create_table :silk_users do |t|
      t.timestamps
      t.string :login, :null => false
      t.string :crypted_password, :null => false
      t.string :password_salt, :null => false
      t.string :persistence_token, :null => false
      t.integer :login_count, :default => 0, :null => false
      t.datetime :last_request_at
      t.datetime :last_login_at
      t.datetime :current_login_at
      t.string :last_login_ip
      t.string :current_login_ip
    end
    
    add_index :silk_users, :login
    add_index :silk_users, :persistence_token
    add_index :silk_users, :last_request_at
  end
 
  def self.down
    drop_table :silk_users
  end
end