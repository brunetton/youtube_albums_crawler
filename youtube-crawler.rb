#!/usr/bin/env ruby

require 'rubygems'
require 'nokogiri'
require 'open-uri'
require "docopt"

doc = <<DOCOPT
Usage:
#{__FILE__} <url>

Convert given youtube video link to mp3, using youtube-dl and avconv.
Audio level normalized using loudnorm audio filter (http://ffmpeg.org/ffmpeg-all.html#loudnorm)

DOCOPT

begin
  args = Docopt::docopt(doc)
rescue Docopt::Exit => e
  puts e.message
  exit
end

url = args['<url>']

# Check youtube url
if match = url.match(/(.*)youtube(.*)\/watch\?v=([^#\&\?]+)/)  # TODO: allow video ID
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
video_filename_file_compliant = "#{video_title.gsub('/','-').gsub('`','\'')}-#{video_id}.txt"
File.open(video_filename_file_compliant, 'w') { |file| file.write(video_description) }

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
mp3_filename = File.basename(video_file.gsub('`','\''), '.*') + ".mp3"
command = "avconv -i \"#{video_file}\" -c:a mp3 -filter:a loudnorm=i=-10 -qscale:a 2 \"#{mp3_filename}\""
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
