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

def get_lesson_code
  get_description[/.*\[([^\]]*)/, 1]
end

def send_email(who, body)
  # bunlar config dosyasından alınmalı
  from = "mail@example.com"
  to = get_from_email get_content
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

def gist_clone(path, gist_no)
  begin
    FileUtils.mkdir_p(path) unless File.exist? path
    FileUtils.chdir(path)
    `git clone git@gist.github.com:#{gist_no}.git `
  rescue
    $stderr.puts "klonlama işleminde hata."
    exit(1)
  end
end

def main
  gist = GistApi.new get_gist_no
  who = get_from_email get_content

  if ! File.exist? CONFIG_FILE
    $stderr.puts "config.yml dosyası yok."
    exit(1)
  end
  config = YAML::parse(File.open(CONFIG_FILE))

  # gist dedigin private olmalı
  if gist.public?
    send_email(who, "Geçersiz Gist.\nGist'iniz private olmalıdır.")
    exit(1)

  # forku varsa olmaz
  elsif gist.hasfork?
    send_email(who, "Geçersiz Gist.\nGist'iniz forklara sahip olmamalıdır.")
    exit(1)

  # tarihi gecmis mi
  lesson = config.transform[get_description]
  date_diff = lesson['end_date'] - Date.today
  elsif dat_diff.zero?
    send_email(who, "Geçersiz Gist.\nÖdev süresi doldu.")

  # sorun yok
  else
    gist_clone(get_lesson_code+lesson['odev_adi'], get_gist_no)
    send_email(who, "Gistiniz kaydedildi.")
  end
end

# p get_gist_no get_content
# p get_from_email get_content
