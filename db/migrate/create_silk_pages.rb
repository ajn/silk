class CreateSilkPages < ActiveRecord::Migration
  def self.up
    create_table :silk_pages do |t|
      t.string :path,       :null => false
      t.string :title,      :null => true
      t.string :layout,     :null => true
      t.text   :meta_tags,  :null => true
      t.timestamps
    end
    add_index :silk_pages, :path, :unique => true
  end

  def self.down
    drop_table :silk_pages
  end
end
