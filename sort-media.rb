#!/usr/bin/env ruby

require 'mini_exiftool'
require 'digest'

if ARGV.size == 0
  puts "Sorts (moves) photo and video files into directories by year and month."
  puts "Subdirectories in source_dir are not traversed."
  puts ""
  puts "Usage: sort-media source_dir photo_dest_dir video_dest_dir"
  puts ""
  exit
end

source_dir = ARGV[0].gsub(/\/$/,'') # remove trailing slash
photo_dest_dir = ARGV[1].gsub(/\/$/,'') # remove trailing slash
video_dest_dir = ARGV[2].gsub(/\/$/,'') # ditto

Dir.glob(source_dir) do |dir|
  Dir.foreach(dir) do |file|
    next if file == '.' || file == '..'
    path = "#{dir}/#{file}"
    new_dir = ''
    begin
      media = MiniExiftool.new path
      if media.date_time_original
        file_time = media.date_time_original
      elsif media.create_date
        file_time = media.create_date
      elsif media.file_modify_date
        file_time = media.file_modify_date
      end
    rescue
      STDERR.puts "Error reading file #{file}"
      next
    end
    if media.mime_type.to_s =~ /image/
      new_dir += photo_dest_dir
    end
    if media.mime_type.to_s =~ /video/
      new_dir += video_dest_dir
    end

    file_year = file_time.to_s[0,4]
    file_month = file_time.to_s[5,2]
    new_dir += "/#{file_year}"
    unless Dir.exists?(new_dir)
      # Dir.mkdir(new_dir)
      puts "would mkdir #{new_dir}"
    end
    new_dir += "/#{file_month}"
    unless Dir.exists?(new_dir)
      # Dir.mkdir(new_dir)
      puts "would mkdir #{new_dir}"
    end
    if File.exists?("#{new_dir}/#{file}")
      if Digest::MD5.file(path).hexdigest == Digest::MD5.file("#{new_dir}/#{file}").hexdigest
        puts "not copying #{path}, file already exists. Would delete source."
      end
    else
      # FileUtils.mv(path, new_dir)
      puts "would move #{path} to #{new_dir}"
    end
  end
end
