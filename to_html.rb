require 'rubygems'
require 'yaml'

CITIES = YAML::load_file(ARGV[0])

# average radius of the earth
RADIUS = 6371010.0

# ratio of route to great circle distance to be considered "bad". this will
# vary regionally (i.e: much higher in the mountains), so should be found by
# experiment.
FACTOR = 4

# calculate the great circle distance
# from wikipedia: 
# arctan(sqrt((cos(phi_f) * sin(Delta_lambda))^2 + 
#             (cos(phi_s) * sin(phi_f) - sin(phi_s) * cos(phi_f) * cos(Delta_lambda)^2)) / 
#        (sin(phi_s) * sin(phi_f) + cos(phi_s) * cos(phi_f) * cos(Delta_lambda)))
def great_circle(a, b)
  lambda = Math::PI * (a[1] - b[1]) / 180.0
  phi_s = Math::PI * a[0] / 180.0
  phi_f = Math::PI * b[0] / 180.0

  sin_phi_s = Math::sin(phi_s)
  sin_phi_f = Math::sin(phi_f)
  sin_lambda = Math::sin(lambda)
  cos_phi_s = Math::cos(phi_s)
  cos_phi_f = Math::cos(phi_f)
  cos_lambda = Math::cos(lambda)

  sigma = Math::atan2(Math::sqrt((cos_phi_f * sin_lambda)**2 + (cos_phi_s * sin_phi_f - sin_phi_s * cos_phi_f * cos_lambda)**2),
                      sin_phi_s * sin_phi_f + cos_phi_s * cos_phi_f * cos_lambda)

  return RADIUS * sigma
end

# define this as the success test - whether something worked or
# not. return a :symbol, which will be used as the CSS class for
# the table cell.
def css_class(from, to, dist)
  if dist.nil?
    return :fail
  else
    if dist > FACTOR * great_circle(CITIES[from], CITIES[to])
      return :bad
    elsif dist > 0.0
      return :success
    else
      return :zero
    end
  end
end

city_dist = {}
File.readlines(ARGV[1]).each do |line|
  from, to, dist = line.split(/;/)
  if dist == "NO ROUTE"
    dist = nil
  else
    dist = dist.to_f
  end
  if city_dist[from].nil?
    city_dist[from] = { to => dist }
  else
    city_dist[from][to] = dist
  end
end

city_names = CITIES.keys.sort
puts <<END
<html><head><title>Fjarlægðir á Íslandi</title>
<style type="text/css">
a.success { color: green; }
a.fail { color: red; }
a.zero { color: #888; }
a.bad { color: #fa0; }
</style>
</head><body>
END

puts "<table><tr><th></th>"
city_names.each do |to| 
  to_pos = CITIES[to]
  url = "http://maps.cloudmade.com/?lat=#{to_pos[0]}&lng=#{to_pos[1]}&zoom=6"
  puts "<th><a href=\"#{url}\">#{to}</a></th>" 
end
puts "</tr>"
counters = {}
city_names.each do |from|
  from_pos = CITIES[from]
  url = "http://maps.cloudmade.com/?lat=#{from_pos[0]}&lng=#{from_pos[1]}&zoom=6"
  puts "<tr><td><a href=\"#{url}\">#{from}</a></td>" 
  city_names.each do |to|
    to_pos = CITIES[to]
    dist = city_dist[from][to]
    cc = css_class(from, to, dist)
    counters[cc] = (counters[cc] || 0) + 1
    url = "http://maps.cloudmade.com/?directions=#{[from_pos,to_pos].flatten.join(',')}&lat=#{0.5*(from_pos[0]+to_pos[0])}&lng=#{0.5*(from_pos[1]+to_pos[1])}&zoom=6"
    if from == to
      puts "<td>X</td>"
    elsif from == 'Vestmannaeyjar' or to == 'Vestmannaeyjar'
      puts "<td>Herjólfur</td>"
    elsif dist.nil? or dist == 0
      puts "<td><a href='#{url}' class='#{cc}'>FAIL</a></td>"
    else
      title_pretty_dist = dist.round.to_s.gsub(/(\d)(\d{3})$/, '\1.\2')
      pretty_dist = title_pretty_dist.to_i.to_s
      puts "<td><a href='#{url}' title='#{title_pretty_dist} km' class='#{cc}'>#{pretty_dist} km</a></td>"
    end
  end
  puts "</tr>"
end
puts "</table>"
total = city_names.length ** 2
counters.each do |cc, n|
  puts "<!--p>Class #{cc}: #{n} of #{total} (#{(100.0*n)/total}%)</p-->"
end
puts "</body></html>"
