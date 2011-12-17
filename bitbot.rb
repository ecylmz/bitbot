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

# Genel mail gönderimi
def send_email(who, body, config)
  # bunlar config dosyasından alınmalı
  from = config.transform['main']['email']
  to = "#{get_from_email get_content}"
  p = config.transform['main']['password']
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

# hoca mı mail atmış, onun kontrolunde kullanılıyor
# hoca mail adresini ve mevcut ödev adını dönüyor.
def which_teacher(config, get_from_email)
  result = nil
  config.transform.collect do |k, v|
    if get_from_email == v['email']
      result = { :name => get_from_email, :hw => config.transform[k]['hw_name'], :lesson_code => k}
      break
    end
  end
  result
end

# odevleri arşivleyelim
def create_archive(hw_path)
  `tar czvf #{hw_path.split("/")[1]}.tar.gz #{hw_path}`
end

# hocaya eki olan bi mail hazırlayalım.
def send_email_teacher(teacher, file, config)
  filecontent = File.read(file)
  encodedcontent = [filecontent].pack("m")
  marker = "AUNIQUEMARKER"

  from = config.transform['main']['email']
  to = "#{teacher}"
  p = config.transform['main']['password']
  content = <<EOF
From: #{from}
To: #{to}
subject: Ödev Raporu
Date: #{Time.now.rfc2822}
MIME-Version: 1.0
Content-Type: multipart/mixed; boundary=#{marker}
--#{marker}
Content-Type: text/plain
Content-Transfer-Encoding:8bit

Ödevler ekteki dosyada.
--#{marker}
Content-Type: multipart/mixed; name=\"#{file}\"
Content-Transfer-Encoding:base64
Content-Disposition: attachment; filename="#{file}"

#{encodedcontent}
#--#{marker}--
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

  # mail atan hoca mı ?
  if ! which_teacher(config, get_from_email(get_content)).nil?
    info_teacher = which_teacher(config, get_from_email(get_content))
    if info_teacher[:name]
      create_archive(info_teacher[:lesson_code] + "/" + info_teacher[:hw])
      send_email_teacher(info_teacher[:name], info_teacher[:hw]+".tar.gz", config)
      exit(0)
    end
  end

  # gist dedigin private olmalı
  if gist.public?
    send_email(who, "Geçersiz Gist.\nGist'iniz private olmalıdır.", config)
    exit(1)
  end

  # forku varsa olmaz
  if gist.hasfork?
    send_email(who, "Geçersiz Gist.\nGist'iniz forklara sahip olmamalıdır.", config)
    exit(1)
  end

  # ders kodu var mı bakalım
  lesson = config.transform[get_lesson_code(gist.get_description)]
  if lesson.nil?
    send_email(who, "Geçersiz Gist\nGist'in description kısmında [ders_kodu] yok veya hatalı ders kodu.", config)
    exit(1)
  end

  # tarihi gecmis mi
  date_diff = lesson['end_date'] - Date.today
  if date_diff.zero?
    send_email(who, "Geçersiz Gist.\nÖdev süresi doldu.", config)
    exit(1)
  end



  # sorun yok
  gist_clone(get_lesson_code(gist.get_description) + "/" + lesson['hw_name'], 
             get_gist_no(get_content), 
             get_student_number(gist.get_description) + "_" + gist.get_username)
  send_email(who, "Gistiniz kaydedildi.", config)
end

main
