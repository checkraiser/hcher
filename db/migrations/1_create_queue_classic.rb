require 'active_record'
require 'pg'
require 'yaml'

dbconfig = YAML::load(File.open(File.expand_path('./db') + '/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)
ActiveRecord::Schema.define do	
	  create_table :queue_classic_jobs do |t|
	    t.string :q_name
	    t.string :method
	    t.text :args
	    t.timestamp :locked_at
	  end
	  add_index :queue_classic_jobs, :id	
end