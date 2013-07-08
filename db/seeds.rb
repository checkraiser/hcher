# encoding: UTF-8
require 'active_record'
require 'pg'
require 'json'
require 'yaml'

dbconfig = YAML::load(File.open(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)

class Source < ActiveRecord::Base
end

class Category < ActiveRecord::Base
	has_many :posts
	has_many :sites
end

class Engine < ActiveRecord::Base
	has_many :sites
end

class Post < ActiveRecord::Base
	belongs_to :category
	def to_post
		codes = "[b]Downloads:[/b]\n[code]"
		arr = JSON.parse(self.download)
		arr.each do |item|
			codes += item + "\n"
		end
		codes += "[/code]"
		return self.description + "\n" + codes
	end
end

class Site < ActiveRecord::Base
	
	belongs_to :engine
	has_many :credentials
	belongs_to :category	
end

class Credential < ActiveRecord::Base
	belongs_to :site
end

Category.where(:name => "Music").first_or_create!
Category.where(:name => "Software").first_or_create!
Category.where(:name => "Magazine").first_or_create!
Category.where(:name => "Comic").first_or_create!
Category.where(:name => "Game").first_or_create!
Category.where(:name => "eBook").first_or_create!
Category.where(:name => "elearning").first_or_create!
Category.where(:name => "Movie").first_or_create!
Category.where(:name => "TV").first_or_create!
Category.where(:name => "Anime").first_or_create!
vBulletin = Engine.where(:name => "vBulletin").first
if vBulletin.nil? then
	vBulletin = Engine.new(:name => "vBulletin")
	vBulletin.login_name = :vb_login_username
	vBulletin.password_name = :vb_login_password
	vBulletin.login_action = [{:action =>["login.php?do=login"]},{:id => ["navbar_loginform","login"]}].to_json
	vBulletin.new_thread = "newthread.php?do=newthread&f="
	vBulletin.post_thread = "newthread.php?do=postthread&f="
	vBulletin.post_action = [{:name => "vbform"}].to_json
	vBulletin.subject_name = "subject"
	vBulletin.message_name = "message"
	vBulletin.prefix_name = "prefixid"
	vBulletin.save! rescue "created vBulletin error"
end


#Source.where(:name => "avaxhome", :pattern => "avaxho.me", :type2 => "1").first_or_create!