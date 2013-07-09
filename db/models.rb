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
	def to_post(isburst=false)
		codes = "[b]Downloads:[/b]\n[code]"
		arr = JSON.parse(self.download)
		arr.each do |item|
			codes += item + "\n"
		end
		codes += "[/code]"
		result = self.description + "\n" + codes
	end
end

class Site < ActiveRecord::Base
	
	belongs_to :engine
	has_many :credentials
	belongs_to :category	
	has_many :transactions, :dependent => :destroy do 
		def failed
			where('transactions.status' => nil)
		end
	end
	has_many :posts, :through => :transactions 
			
end

class Credential < ActiveRecord::Base
	belongs_to :site
end

class Transaction < ActiveRecord::Base

	belongs_to :site
	belongs_to :post
	
	def self.post(site, post)
		begin
			transaction = Transaction.where(site_id: site, post_id: post).first

			transaction = Transaction.new(site_id: site, post_id: post) if transaction.nil?

			site = transaction.site
			post = transaction.post
			credential = site.credentials.where(:status => false).first
			if credential.nil? then 
				puts "busy all account"
				return nil
			end
			credential.status = true
			credential.save! rescue puts "status error"
			agent = Mechanize.new do |a|
			    a.follow_meta_refresh = true
			    a.user_agent_alias = 'Mac Safari'
			    a.idle_timeout = 0.9
			end
			
			page = transaction.login(agent, credential)
			return nil if page.nil?
			
			sleep 1+rand(3)
			result =  transaction.newpost(agent)
			#File.open("result.html","w").write(result.content) if result
			if result and result.content.include?(post.title)				
				transaction.status = true
				credential.status = false
				transaction.save! rescue "save transaction ok"
				credential.save! rescue "save credential ok"
				puts "Success"
				sleep site.sleeptime
			end
			post.save! rescue "error saving"
			credential.status = false
			credential.save! rescue "save credential ok"
			return result
		rescue Exception => e
			puts "Error:#{e}"
			credential.status = false
			credential.save! rescue "status error"
			return nil
		end
	end
	
	
	
	def login(agent, credential)
		begin		
			puts "login #{site.home_page}"
			page = agent.get(site.home_page)
			raise Exception.new("get home page error") if page.nil?
			login_form = page.forms.select { |form| form.submits.select {|f| f.value == site.login_action }.count > 0}.first
			
			raise Exception.new("get login form error") if login_form.nil?
				
			

			login_form[site.engine.login_name] = credential.username if login_form[site.engine.login_name]
			login_form[site.engine.password_name] = credential.password if login_form[site.engine.password_name]
			
			button = login_form.button_with(:value => site.login_action)

			page = agent.submit(login_form, button)
			File.open("login.html","w").write(page.content)
			

		rescue Exception => e
			raise e
		end
	end
	def newpost(agent)
		begin
			
			engine = site.engine
			puts engine.name + " " + engine.subject_name
			encode = site.encoder || "UTF-8"
			page = agent.get(site.new_thread)
			pbody = page.content.gsub('maxlength="85" Array','maxlength="85" />').gsub('newthread.php?do=postthread&amp;f=158','http://wasza-muza.pl/newthread.php?do=postthread&amp;f=158')
			page  = Mechanize::Page.new(nil, {'content-type'=>'text/html'},pbody, nil, agent)
			val = nil
			if site.root_page  then 
				x = site.root_page.split(",").to_a										
				doc = page.parser.xpath(x[0]).to_html	
				File.open("doc.html","w").write(doc)							
				val = doc.match(/#{x[1]}/)[x[2].to_i]	
			end
			post_form = page.forms.select { |form| form.submits.select {|f| f.value == site.post_thread }.count > 0}.first

			if post_form.nil? then 

				

				File.open("error.html","w").write(pbody)
				
				puts "Post form error"
				raise Exception.new("Post form error")
			end
			
			
			puts "posting " + post.title.force_encoding(encode)
			
			
			post_form[engine.subject_name] = post.title.force_encoding(encode)  if post_form[engine.subject_name]
			
			
			post_form[engine.message_name] = post.to_post.force_encoding(encode) if post_form[engine.message_name]
			if engine.prefix_name then 
				post_form[engine.prefix_name] = site.prefix if  post_form[engine.prefix_name] and site.prefix
			end
			if site.root_page  then 
				x = site.root_page.split(",").to_a															
				puts val		
				post_form.radiobutton_with(:value => val).check	
				#post_form[x[3]]	= val if post_form[x[3]] and val
			end
		
				
			
			button = post_form.button_with(:value => site.post_thread)		
			
			page = agent.submit(post_form, button)
			
			post_form = page.forms.select { |form| form.submits.select {|f| f.value == site.preview_action }.count > 0}.first
			if post_form then 
				File.open("error.html","w").write(page.content)
				raise Exception.new("Error posting")
			end
			return page
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
		    	#puts "posting #{post.title} to #{site.home_page}"
		    	
			    Transaction.post(site.id, post.id)
				
		    end
		    
		end
	end
	def self.beginsite(cat, post, site)
		cat = Category.find(cat)
		site = Site.find(site)
		if site.category_id != cat.id then return nil end
		post = Post.find(post)
				
		tr = Transaction.where(:site_id => site.id, :post_id => post.id).first
			
			#queue = QC::Queue.new("posting_jobs2")
		    #queue.enqueue("Transaction.post",[site.id, post.id])	
	    if tr.nil? then 
	    	#puts "posting #{post.title} to #{site.home_page}"
	    	
		    Transaction.post(site.id, post.id)
			
	    end		   		
	end
	def self.beginrestart(site)		
		site = Site.find(site)		
		trs = site.transactions.failed
		if trs.count > 0 then 
			
			trs.each do |tr|			    	   
			    Transaction.post(tr.site.id, tr.post.id)
		    end	
		    
		end
	end
end

