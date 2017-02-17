# Youtube albums crawler

=> Work in progress !

## What is it ?

The aim of this project is to download and convert to mp3 full albums found in youtube.
It relays on the excellent [youtube-dl](https://rg3.github.io/youtube-dl/) and the non less excellent [avconv](https://libav.org/avconv.html).

## Limitations

For now the script only download video, converts it to mp3 and save video description in a txt file for future treatments (see TODO section).

## Installation

sudo aptitude install youtube-dl avconv
sudo gem install docopt
sudo gem install nokogiri

## Usage

    youtube-crawler.rb <youtube_video_url>

## TODO

  * automatic audio files cutting (silence detect) => will use external tool like [mp3splt](http://mp3splt.sourceforge.net/mp3splt_page/screenshots.php)
  * automatic resulting audio files naming and **tagging** (with the help of video description)
