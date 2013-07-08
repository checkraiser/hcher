# encoding: UTF-8

module Avaxhome	
	extend self
	def gettitle(page)
		return page.parser.xpath("/html/body/div[2]/div[2]/div[2]/div/div/div/div[6]/div/div/div[7]/div[2]/b").to_html.gsub!('<b>','').gsub!('</b>','')
	end
	def getinfo(page)	
		#pattern = /(<img src=\")([\w \/ \: \. \" \= \_ \- \) \(]*) ([\>])/	
		#pattern = /(\<img )(.*)(\<\/a\>\<\/div\>)/
		#pattern_img =  /(\<img .+\"\>)(\<.+)/
		#pattern_td = /(\<td .+\"\>)([\<].+)/
		#pattern_iframe = /(\<iframe)(.*)(\<\/iframe\>)/
		info = page.parser.xpath("/html/body/div[2]/div[2]/div[2]/div/div/div/div[6]/div/div/div[7]").to_html
		File.open("origin.txt","w").write(info)
		#info = info.gsub(pattern_img,'\1' + '</img>' + '\2').gsub(pattern_td,'\1' + '</td>' + '\2').gsub(pattern_iframe,'').gsub('<br>','<br/>')
		#File.open("info.txt","w").write(info)
		info = Nokogiri::HTML(info).text
		#r = ReverseMarkdown.new
		#markdown = r.parse_string(info)
		#mach = markdown.match /(\[)(1)(\]\: )(.*)/
		return info
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
			
			agent2 = Mechanize.new do |a|
			    a.follow_meta_refresh = true
			    a.user_agent_alias = 'Mac Safari'
			    a.idle_timeout = 0.9
			end
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
					if item[:href].include?('folder') then 
						page3 = agent2.get(item[:href])
						items2 = page3.parser.xpath("/html/body/div[3]/div/div/table/tbody//tr/td[2]//a/@href")
						items2.each do |it|
							links << "http://uploaded.net/" + it.value
						end
					else
						links << item[:href] 
					end
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

				p = Post.where(title: title,  source: url).first_or_create!
				p.description = info
				p.source = url
				p.category = cat
				p.download = links2.to_json
				
				if p.save! then			
					puts "finished importing, queuing post job"		
					#postQueue = QC::Queue.new("posting_jobs")
					#postQueue.enqueue("Starter.begin",[cat.id, post.id])
					Starter.begin(cat.id, p.id)
				end
			end
				
	end			
end