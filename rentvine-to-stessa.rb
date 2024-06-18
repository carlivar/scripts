#!/usr/bin/env ruby
require 'csv'

# the property address to list in all of the csv output lines
PROPERTY_ADDRESS = '123 Main St'

if ARGV.size < 2
  puts "Usage: rentvine-to-stessa.rb <input file> <output file>"
  exit
end

infile = ARGV[0]
outfile = ARGV[1]

def parse_category(i)
  category = case i.gsub('"','')
  when /Gas \& Electric/
    "Gas & Electric"
  when "Management Fee"
    "Property Management"
  when "Owner Draws"
    "Owner Distributions"
  when "Utilites" # sic
    "Rents"
  when "Utilities"
    "Rents"
  when "Utilities - Sewer"
    "Water & Sewer"
  when /Rent /
    "Rents"
  when "Owner Maint. Coordination Fee"
    "Service Calls"
  when "Lease Renewal Fee"
    "Leasing Commissions"
  when /Repairs and Maintenance/
    "Repairs & Maintenance"
  when "Leasing Fee Expense"
    "Leasing Commissions"
  when "Utility Expense"
    "Water & Sewer"
  when /Maintenance Cap Improvement Expense/
    "Repairs & Maintenance"
  when /one time pet fee/i
    "Pet Fees"
  when /maintenance expense recoveries/i
    "Tenant Pass-Throughs"
  else
    "Uncategorized"
  end
  puts "Warning: category #{i} is unknown!" if category == 'Uncategorized'
  return category
end

def parse_unit(i)
  i =~ /Apt (.)/
  if $1
    return "Unit #{$1}"
  else
    return ''
  end
end

lines = []
File.foreach(infile).with_index do |line, line_num|
  next if line_num == 0
  line_a = line.parse_csv(liberal_parsing: true)
  next if line_a[0] == 'Starting Balance'
  amount = line_a[6].delete('$,').to_f - line_a[7].delete('$,').to_f # Increase - Decrease
  lines <<
  [
    line_a[2].gsub('-','/'),
    amount,
    line_a[3],
    line_a[4],
    parse_category(line_a[0]),
    PROPERTY_ADDRESS,    
    parse_unit(line_a[1])
  ]
end

File.open(outfile, "w") do |f|
  f.write %w(Date Amount Payee Description Category Property Unit).to_csv
  lines.each do |line|
    f.write line.to_csv
  end
end

