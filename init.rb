#encoding: utf-8

require 'rss'
require 'mechanize'
require 'open-uri'
require 'nokogiri'
require 'json'
require 'date'
require 'redis'
require './db/models'
require './config'
require './lib/revserse_markdown'


SID = ARGV[0] || Site.last.id
filename = "Music"
inputs = []
File.readlines("driver/sources/#{filename}.txt").each_with_index do |line, index|
	inputs << line
end

inputs.each do |input|
	puts "imported #{filename} #{input}"
	#pendingQueue.enqueue("Avaxhome.import",[filename, input])
	Avaxhome.import(filename, input)	
end