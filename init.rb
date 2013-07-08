#encoding: utf-8

require 'rss'
require 'mechanize'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'date'
require 'redis'
require './db/models'
require './lib/revserse_markdown'
require './lib/avaxhome'

dbconfig = YAML::load(File.open(File.dirname(__FILE__) + '/config/database.yml'))
ActiveRecord::Base.establish_connection(dbconfig)

account = YAML::load(File.open(File.dirname(__FILE__) + '/config/database.yml'))['account1']
USERNAME= account['username']
PASSWORD= account['password']
category = ARGV[0] || "Music"
inputs = []
File.readlines("driver/sources/#{category}.txt").each_with_index do |line, index|
	inputs << line
end

inputs.each do |input|	
	#pendingQueue.enqueue("Avaxhome.import",[filename, input])
	Avaxhome.import(filename, input)	
end