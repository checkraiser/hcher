# encoding: UTF-8







class Source <ActiveRecord::Base

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
	has_one :credential
	belongs_to :category	
	
end

class Credential < ActiveRecord::Base
	belongs_to :site
end

class Transaction < ActiveRecord::Base

	belongs_to :site
	belongs_to :post
	
	def self.post(site, post)
		begin
			transaction = Transaction.where(site_id: site, post_id: post).first_or_create!

			return false if transaction.nil?

			site = transaction.site
			post = transaction.post
			agent = Mechanize.new do |a|
			    a.follow_meta_refresh = true
			    a.user_agent_alias = 'Mac Safari'
			    a.idle_timeout = 0.9
			end
			puts "logining in ..."
			page = transaction.login(agent)
			return nil if page.nil?
			puts "posting ..."
			result =  transaction.newpost(agent)
			if result and result.content.include?(post.title)				
				transaction.status = true
				puts "Success"
				sleep 30
			end
			post.save! rescue "error saving"
			
			return result
		rescue Exception => e
			puts "Error:#{e}"
			
			return nil
		end
	end
	
	
	
	def login(agent)
		begin		
			puts "login #{site.home_page}"
			page = agent.get(site.home_page)
			raise Exception.new("get home page error") if page.nil?
			login_form = nil
			if site.login_action then 				
				login_form ||= page.form_with(:action => site.login_action)				
			end

			arr2 = JSON.parse(site.engine.login_action)
			
			arr2.each do |ar|
				ar.each do |k,v|
					v.each do |vi|
						login_form ||= page.form_with({k => vi})
					end
				end
			end
			raise Exception.new("get login form error") if login_form.nil?
				
			

			login_form[site.engine.login_name] = site.credential.username if login_form[site.engine.login_name]
			login_form[site.engine.password_name] = site.credential.password if login_form[site.engine.password_name]
			

			agent.submit login_form

			

		rescue Exception => e
			raise e
		end
	end
	def newpost(agent)
		begin
			puts "begin posting"
			engine = site.engine

			
			page = agent.get(site.new_thread)
			#File.open("test.html","w").write(page.content)
			

			post_form = page.form_with(:action => site.post_thread) if site.post_thread
									
			
			#puts post_form.inspect
			encode = site.encoder || "UTF-8"
			puts "posting " +post.title.force_encoding(encode)
			post_form[engine.subject_name] = post.title.force_encoding(encode)  if post_form[engine.subject_name]
			post_form[engine.message_name] = post.to_post.force_encoding(encode) if post_form[engine.message_name]
			post_form[engine.prefix_name] = site.prefix.force_encoding(encode) if  post_form[engine.prefix_name] and site.prefix
							
			return agent.submit post_form 
		rescue Exception => e
			raise e
		end
	end
end

class Starter 
	def self.begin(cat, post)
		cat = Category.find(cat)
		sites = Site.where(:category_id => cat.id)
		post = Post.find(post)
		sites.each do |site|			
			tr = Transaction.where(:site_id => site.id, :post_id => post.id).first
			
			#queue = QC::Queue.new("posting_jobs2")
		    #queue.enqueue("Transaction.post",[site.id, post.id])	
		    if tr.nil? then 
		    	puts "posting #{post.title} to #{site.home_page}"
		    	
			    Transaction.post(site.id, post.id)
				
		    end
		    
		end
	end
end

