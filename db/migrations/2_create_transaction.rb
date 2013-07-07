require 'active_record'
require 'pg'
require 'yaml'

dbconfig = YAML::load(File.open(File.expand_path('./db') + '/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Schema.define do	
	  create_table :transactions do |t|
	    t.integer :post_id
	    t.integer :site_id
	    t.boolean :status	    
	  end	  
end