#!/usr/bin/env ruby

require 'rubygems'
require "docopt"
require 'rainbow'

doc = <<DOCOPT
Usage:
#{__FILE__} <url>
#{__FILE__} --from-file <filename> [--numbering]

Options:
  --numbering                 add a number at begining of mp3 files (ex: 01 - blabla.mp3)
  --youtubedl-args <args>     custom additional Youtube-dl args

Convert given video link, or all video links found in given file to mp3, using youtube-dl and avconv.
Audio level normalized using loudnorm audio filter (http://ffmpeg.org/ffmpeg-all.html#loudnorm)

DOCOPT

# https://regexr.com/3anm9
YOUTUBE_LINK_REGEXP = /(?:youtube\.com\/\S*(?:(?:\/e(?:mbed))?\/|watch\?(?:\S*?&?v\=))|youtu\.be\/)([a-zA-Z0-9_-]{6,11})/
YOUTUBEDL_DEFAULT_ARGS = "-f bestaudio --no-playlist --console-title --exec 'ffmpeg -i {} -c:a mp3 -filter:a loudnorm=i=-18:lra=17 -qscale:a 2 {}.mp3 && rm {}'"
FFMPEG_OPTIONS = "-c:a mp3 -filter:a loudnorm=i=-18:lra=17 -qscale:a 2"

def treat_url(url, audio_file_number=nil)
  # Check if this video has already been downloaded
  if match = url.match(YOUTUBE_LINK_REGEXP)
    video_id = match.captures[0]
    already_exting_filename = Dir.foreach(Dir.pwd).detect{|f| f[video_id]}
    if already_exting_filename
      puts Rainbow("- #{video_id} has already been downloaded (\"#{already_exting_filename}\")\n-> abording").crimson
      exit -1
    end
  end
  # Call youtube-dl to download sound and call ffmpeg
  youtubedl_args = YOUTUBEDL_DEFAULT_ARGS
  youtubedl_args += ' ' + $args['youtubedl-args'] if $args['youtubedl-args']
  command = "youtube-dl #{youtubedl_args} \"#{url}\""
  puts Rainbow("--> Running \"#{command}\"").bright
  system(command)
end


begin
  $args = Docopt::docopt(doc)
rescue Docopt::Exit => e
  puts e.message
  exit
end

if $args['<url>']
  url = $args['<url>']
  treat_url(url)
  puts "\n\n--> End"
elsif $args['<filename>']
  file_number = 0
  File.readlines($args['<filename>']).each do |line|
    file_number += 1
    url = line.strip
    puts "\n\n***** #{url}\n"
    number = $args['--numbering'] ? file_number : nil
    treat_url(url, number)
  end
  puts "\n\nEnd\n#{file_number} files treated."
end
