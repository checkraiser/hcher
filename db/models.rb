# encoding: UTF-8
require 'active_record'
require 'pg'
require 'json'
require 'yaml'


dbconfig = YAML::load(File.open(File.dirname(__FILE__) + '/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)



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

	def get_new_thread
		if new_thread.present?
			"#{new_thread}#{forum.to_s}"
		else
			"#{engine.new_thread}#{forum.to_s}"
		end
	end
	def get_post_thread
		if post_thread.present?
			"#{post_thread}#{forum.to_s}"
		else
			"#{engine.post_thread}#{forum.to_s}"
		end
	end
	def full_new_thread
		"#{root_page}" + "/" + "#{get_new_thread}"
	end
	def full_post_thread
		"#{root_page}" + "/" + "#{get_post_thread}"
	end
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
				post.published = true 
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
			puts "posting " +post.title.force_encoding("UTF-8")
			post_form[engine.subject_name] = post.title.force_encoding("UTF-8")  if post_form[engine.subject_name]
			post_form[engine.message_name] = post.to_post.force_encoding("UTF-8") if post_form[engine.message_name]
			post_form[engine.prefix_name] = site.prefix.force_encoding("UTF-8") if  post_form[engine.prefix_name] and site.prefix
							
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

module Avaxhome	
	extend self
	def gettitle(page)
		return page.parser.xpath("/html/body/div[2]/div[2]/div[2]/div/div/div/div[6]/div/div/div[7]/div[2]/b").to_html.gsub!('<b>','').gsub!('</b>','')
	end
	def getinfo(page)		
		info = page.parser.xpath("/html/body/div[2]/div[2]/div[2]/div/div/div/div[6]/div/div/div[7]").to_html
		
		info = info.gsub('></a>','></img></a>').gsub('</a></span>','</a></img></span>').gsub('<br>','<br/>').gsub('</span></img></a>','</span></a>')	
		#File.open("info.txt","w").write(info)
		r = ReverseMarkdown.new
		markdown = r.parse_string(info)
		mach = markdown.match /(\[)(1)(\]\: )(.*)/
		return markdown.gsub(/(\[)(\d*)(\]\: )(.*)/, '').gsub("[![][1] ][2]", "[image]#{mach[4]}[/image]")
	end
	def transf(str)
		str2 = str.gsub("\"","").gsub("{","").split("},")

		res = []
		str2.each do |si|
			temp = {}
			str3 = si.split(",")
			str3.each do |ki|
				ss = ki.split(":")
				temp[ss[0]] = ss[1]
			end
			res << temp
		end

		return res 
	end
	def import(category, url)
			

			ps = Post.where(source: url)
			if ps.count > 0
				cat = Category.where(:name => category).first
				Starter.begin(cat.id, ps.first.id)
				return nil 
			end
			puts "begining import"
			cat = Category.where(:name => category).first
			
			agent2 = Mechanize.new
			agent = Mechanize.new do |a|
			    a.follow_meta_refresh = true
			    a.user_agent_alias = 'Mac Safari'
			    a.idle_timeout = 0.9
			end
			page = agent.get("http://uploaded.net/#login")
			login_form = page.form_with(:action => "io/login") 

			login_form['id'] = USERNAME
			login_form['pw'] = PASSWORD

			agent.submit login_form

			inputs = []
			links = []
						

			page = agent2.get(url)
			title = gettitle(page)
			info = getinfo(page)	
			

			items = page.search('//a').select {|i| i.to_html.upcase.include?("UPLOADED.NET") or i.to_html.upcase.include?("UL.TO")}
			if items.count > 0
				items.each do |item|
					links << item[:href] 
				end

				
				
				puts "uploading ..."
				res = agent.post("http://uploaded.net/io/import",{:urls => links.join("\n")} ,{'X-Requested-With' => 'XMLHttpRequest',
					'Content-Type' =>  'application/x-www-form-urlencoded; charset=UTF-8',
					'Accept' => 'text/javascript, text/html, application/xml, text/xml, */*'})

				results= transf(res.body)

				puts "getting file links"		  
				links2 = []
				
				results.each do |row| 
					links2 << "http://uploaded.net/file/" + row["newAuth"] + "/" + row["filename"] +"\n"  unless row["err"]
				end
				
				p = Post.where(title: title, description: info, source: url, download: links2.to_json, published: false).first_or_create!
				p.description = info
				p.source = url
				p.category = cat
				p.download = links2.to_json
				p.published = false
				if p.save! then			
					puts "finished importing, queuing post job"		
					#postQueue = QC::Queue.new("posting_jobs")
					#postQueue.enqueue("Starter.begin",[cat.id, post.id])
					Starter.begin(cat.id, p.id)
				end
			end
				
	end			
end