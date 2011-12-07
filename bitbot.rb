#!/usr/bin/ruby
# encoding: utf-8

def get_content
  content = File.open("content.txt", "r").read
end

def get_from_email(content)
  r = Regexp.new(/\b[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}\b/)
  content.scan(r).uniq[1]
end

def get_gist_no(content)
  content[/https:\/\/gist.github.com\/(\w+)/, 1]
end

p get_gist_no get_content
p get_from_email get_content
