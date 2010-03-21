class CreateSilkContent < ActiveRecord::Migration
  def self.up
    create_table :silk_content do |t|
      t.string :path
      t.string :name
      t.string :content_type, :null => false, :default => 'html'
      t.text   :body
      t.timestamps
    end
    add_index :silk_content, [:path, :name], :unique => true
  end

  def self.down
    drop_table :silk_content
  end
end