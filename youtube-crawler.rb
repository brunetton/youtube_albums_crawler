#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require "docopt"

doc = <<DOCOPT
Usage:
  #{__FILE__} <url>
DOCOPT

begin
  args = Docopt::docopt(doc)
rescue Docopt::Exit => e
  puts e.message
  exit
end

url = args['<url>']

# Check youtube url
if match = url.match(/(.*)youtube(.*)\/watch\?v=(.*)$/)
  video_id = match.captures[2]
else
  abort("\"#{url}\" is not a valid youtube url !")
end

# Open url
page = Nokogiri::HTML(open(url))
video_description = page.css('p[id="eow-description"]').inner_html.gsub('<br>', "\n")
video_title = page.css('h1[class="watch-title-container"]').text.strip
print "#{video_id}: #{video_title}\n\n#{video_description}\n\n"
# Save text temporary
File.open("#{video_title}-#{video_id}.txt", 'w') { |file| file.write(video_description) }

# Download file
command = "youtube-dl \"#{url}\""
puts "--> Running \"#{command}\""
system(command)
if $?.exitstatus != 0
    exit(-1)
end

# Convert to mp3
video_file = Dir.glob("*#{video_id}*.*").find{|filename| not filename.end_with? '.txt'}
puts "\n\n--> Converting '#{video_file}' to mp3"
mp3_filename = File.basename(video_file, '.*') + ".mp3"
command = "avconv -i \"#{video_file}\" -c:a mp3 -qscale:a 2 \"#{mp3_filename}\""
puts "Running \"#{command}\""
system(command)
if $?.exitstatus != 0
    exit(-1)
end

# Check mp3 file exists and > 0
if not (File.exist?(mp3_filename) and File.size(mp3_filename) > 0)
    abort("OOPS, mp3 file doesn't seems to be generated -> abording")
end

# remove video file
File.delete(video_file)

puts "\n\n--> End"
