class Silk::User < ActiveRecord::Base

  set_table_name :silk_users
  
  acts_as_authentic
    
end