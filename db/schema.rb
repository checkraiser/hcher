# encoding: UTF-8
require 'active_record'
require 'yaml'

dbconfig = YAML::load(File.open(File.expand_path('./config') + '/database.yml'))[ENV['DATABASE']]
ActiveRecord::Base.establish_connection(dbconfig)

ActiveRecord::Schema.define do
	
	create_table :posts do |table|
		table.column :title, :string
		table.column :description, :text		
		table.column :source, :string		
		table.column :download, :text		
		table.column :category_id, :integer
	end			
	create_table :categories do |table|
		table.column :name, :string
	end
	create_table :engines do |table|
		table.column :name, :string
		table.column :login_name, :text
		table.column :password_name, :text
		table.column :login_action, :text
		table.column :new_thread, :text
		table.column :post_thread, :text	
		table.column :subject_name, :text	
		table.column :message_name, :text	
		table.column :prefix_name, :text	
	end
	create_table :sites do |table|
		table.column :engine_id, :integer		
		table.column :home_page, :string
		table.column :forum, :string	
		table.column :category_id, :integer	
		table.column :prefix, :string
		table.column :login_action, :string
		table.column :new_thread, :text
		table.column :post_thread, :text
		table.column :root_page, :text
		table.column :encoder, :string
	end
	create_table :credentials do |table|
		table.column :username, :string
		table.column :password, :string
		table.column :site_id, :integer
		table.column :status, :boolean
	end
	create_table :transactions do |t|
	    t.integer :post_id
	    t.integer :site_id
	    t.boolean :status	    
	  end	  
end