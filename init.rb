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
require './driver/heroturko'



account = YAML::load(File.open(File.dirname(__FILE__) + '/config/uploaded.yml'))[ENV['ACCOUNT']]
USERNAME= account['username']
PASSWORD= account['password']
category = ARGV[0] || "Music"
input = ARGV[1] || "Music"
site = ARGV[2]
site = nil if site == "-1"
puts site
inputs = []
File.readlines("source/#{input}.txt").each_with_index do |line, index|
	inputs << line
end

inputs.each do |input|	
	#pendingQueue.enqueue("Avaxhome.import",[filename, input])	
	Avaxhome.import(category, input, site)	if Avaxhome.recog?(input)
	Heroturko.import(category, input, site)	if Heroturko.recog?(input)
end