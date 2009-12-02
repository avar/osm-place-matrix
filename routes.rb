require 'rubygems'
require 'cloudmade'
require 'yaml'
include CloudMade

API_KEY='f7873dcb2e154020b79ac5b87dd0a483' # PUT YOUR API KEY HERE
CITIES = YAML::load_file(ARGV[0])
CM = Client.from_parameters(API_KEY)

def route_or_nil(from, to)
  backoff = 10
  loop do
    begin
      return CM.routing.route(Point.new(CITIES[from]), Point.new(CITIES[to]))
    rescue Timeout::Error
      STDERR.puts "[#{Time.now}] Timeout, retrying..."
      sleep(backoff)
      backoff = [60 * 30, backoff * 2].min
    rescue HTTPError => e
      STDERR.puts "[#{Time.now}] HTTP error: #{e}, retrying..."
      sleep(backoff)
      backoff = [60 * 30, backoff * 2].min      
    rescue
      STDERR.puts "[#{Time.now}] Other error: #{e}, retrying..."
      sleep(backoff)
      backoff = [60 * 30, backoff * 2].min      
    end
  end
rescue RouteNotFound
  nil
end

num_cities = CITIES.keys.length
CITIES.keys.sort.each do |i|
  CITIES.keys.sort.each do |j|
    r = route_or_nil(i, j)
    if r.nil?
      puts "#{i};#{j};NO ROUTE"
    else
      puts "#{i};#{j};#{r.summary.total_distance}"
    end
  end
end
