#!/usr/bin/ruby
# encoding: utf-8

require "#{File.dirname(__FILE__)}/GistApi"
require 'yaml'
require 'date'
require 'tlsmail'
require 'time'
require 'fileutils'

CONFIG_FILE = "config.yml"

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

def get_lesson_code(description)
  description[/.*\[([^\]]*)/, 1].split[1]
end

def get_student_number(description)
  description[/.*\[([^\]]*)/, 1].split[0]
end

def send_email(who, body)
  # bunlar config dosyasından alınmalı
  from = "mail@example.com"
  to = "#{get_from_email get_content}"
  p = "password"
  content = <<EOF
From: #{from}
To: #{to}
subject: Gönderdiğiniz Ödev
Date: #{Time.now.rfc2822}

#{body}
EOF
  Net::SMTP.enable_tls(OpenSSL::SSL::VERIFY_NONE)
  Net::SMTP.start('smtp.gmail.com', 587, 'gmail.com', from, p, :login) do |smtp|
    smtp.send_message(content, from, to)
  end
end

def gist_clone(path, gist_no, gist_name)
  FileUtils.mkdir_p(path) unless File.exist? path
  FileUtils.chdir(path)
  `git clone git@gist.github.com:#{gist_no}.git #{gist_name}`
  FileUtils.chdir("../..")
end

def main
  gist = GistApi.new get_gist_no(get_content)
  who = get_from_email get_content

  if !File.exist? CONFIG_FILE
    $stderr.puts "config.yml dosyası yok."
    exit(1)
  end
  config = YAML::parse(File.open(CONFIG_FILE))

  # gist dedigin private olmalı
  if gist.public?
    send_email(who, "Geçersiz Gist.\nGist'iniz private olmalıdır.")
    exit(1)
  end

  # forku varsa olmaz
  if gist.hasfork?
    send_email(who, "Geçersiz Gist.\nGist'iniz forklara sahip olmamalıdır.")
    exit(1)
  end

  # ders kodu var mı bakalım
  lesson = config.transform[get_lesson_code(gist.get_description)]
  if lesson.nil?
    send_email(who, "Geçersiz Gist\nGist'in description kısmında [ders_kodu] yok veya hatalı ders kodu.")
    exit(1)
  end

  # tarihi gecmis mi
  date_diff = lesson['end_date'] - Date.today
  if date_diff.zero?
    send_email(who, "Geçersiz Gist.\nÖdev süresi doldu.")
    exit(1)
  end

  # sorun yok
  gist_clone(get_lesson_code(gist.get_description) + "/" + lesson['odev_adi'], get_gist_no(get_content), get_student_number(gist.get_description) + "_" + gist.get_username)
  send_email(who, "Gistiniz kaydedildi.")
end

main
