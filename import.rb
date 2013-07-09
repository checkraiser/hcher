#encoding: utf-8

require 'rss'
require 'mechanize'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'date'

OUTPUTFILE = ARGV[0] || "source/import/album2.txt"

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

def importf(inputs,index)
	sleep 1 + rand(5)
	agent = Mechanize.new do |a|
	    a.follow_meta_refresh = true
	    a.user_agent_alias = 'Mac Safari'
	    a.keep_alive = false
	end
	page = agent.get("http://uploaded.net/#login")
	login_form = page.form_with(:action => "io/login") 

	login_form['id'] = "8899272"
	login_form['pw'] = "Tu228787"

	agent.submit login_form
	links2 = inputs.join("\n")
	puts "uploading ... #{index}"
	sleep 1 + rand(5)
	res = agent.post("http://uploaded.net/io/import",{:urls => links2} ,{'X-Requested-With' => 'XMLHttpRequest',
		'Content-Type' =>  'application/x-www-form-urlencoded; charset=UTF-8',
		'Accept' => 'text/javascript, text/html, application/xml, text/xml, */*'})

	results= transf(res.body)
	 
	open(OUTPUTFILE,"a") do |f|
		results.each do |row| 
			f << "http://uploaded.net/file/" + row["newAuth"] + "/" + row["filename"] +"\n"  unless row["err"]
		end
	end
	puts "completed #{index}"
end



inputs = []
links = []

File.readlines("source/import/album1.txt").each_with_index do |line, index|
	inputs << line
end
sinputs = inputs.each_slice(1200).to_a
th = []
sinputs.each_with_index do |inpus,index|
	th << Thread.new{importf(inpus,index)}
end
th.each do |t|
	t.join 
end
