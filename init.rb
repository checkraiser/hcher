#encoding: utf-8
require 'active_record'
require 'pg'
require 'json'
require 'yaml'
require 'mechanize'
require 'open-uri'
require 'nokogiri'
require 'date'

dbconfig = YAML::load(File.open(File.dirname(__FILE__) + '/config/database.yml'))[ENV['DATABASE']]
ActiveRecord::Base.establish_connection(dbconfig)

require './db/models'
require './lib/revserse_markdown'
require './lib/avaxhome'



account = YAML::load(File.open(File.dirname(__FILE__) + '/config/uploaded.yml'))[ENV['ACCOUNT']]
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