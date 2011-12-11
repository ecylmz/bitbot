#!/usr/bin/ruby
# encoding: utf-8


require 'net/https'
require 'uri'
require 'json'

class GistApi
  attr_reader :gist_no, :data

  def initialize(gist_no)
    @gist_no = gist_no
    uri = URI.parse("https://api.github.com/gists/#{@gist_no}")
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    @data = JSON.parse(response.body)
  end

  def get_username
    @data['user']['login']
  end

  def get_description
    @data['description']
  end

  def hasfork?
    @data['forks'].empty? ? false : true
  end

  def public?
    @data['public']
  end

  def file_number
    @data['files'].size
  end
end

# g = GistApi.new "3d4c61724d37c19d8d5b"
# p g.hasfork?
# p g.file_number
# p g.public?
# p g.get_username
# p g.get_description[/.*\[([^\]]*)/, 1]
