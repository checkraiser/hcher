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
require './driver/avaxhome'



account = YAML::load(File.open(File.dirname(__FILE__) + '/config/uploaded.yml'))[ENV['ACCOUNT']]
USERNAME= account['username']
PASSWORD= account['password']

begin
	site = ARGV[0]
	site = Site.find(site)
	return if site.nil? 
	Starter.beginrestart(site)
rescue Exception => e
	puts e
end