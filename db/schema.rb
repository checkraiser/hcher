# encoding: UTF-8
require 'active_record'
require 'yaml'

dbconfig = YAML::load(File.open(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)

ActiveRecord::Schema.define do
	
	create_table :posts do |table|
		table.column :title, :string
		table.column :description, :text		
		table.column :source, :string		
		table.column :download, :text
		table.column :published, :boolean
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
	end
	create_table :sites do |table|
		table.column :engine, :string		
		table.column :home_page, :string
		table.column :forum, :string	
		table.column :category_id, :integer	
		table.column :prefix, :string
	end
	create_table :credentials do |table|
		table.column :username, :string
		table.column :password, :string
		table.column :site_id, :integer
	end
end