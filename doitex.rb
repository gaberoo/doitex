#!/usr/bin/env ruby

require 'optparse'
require 'bibtex'
require 'serrano'

options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: doitex.rb [options] <aux> <bib>"

  opts.on("-K", "--backup [FILE]", "Create backup of bib file") do |fn|
    options[:backup] = fn
  end

  opts.on("-o", "--output [FILE]", "Write new bib to this file (instead of overwriting old file).") do |fn|
    options[:outfile] = fn
  end

  opts.on("-e", "--email [email]", "Email for CrossRef") do |email|
    options[:email] = email
  end

  opts.on("--[no-]keep-url", "Keep URL from record.") do |u|
    options[:url] = u
  end

  opts.on("-v", "--[no-]verbose", "Output verbose messages") do |v|
    options[:verbose] = v
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end.parse!

bib_fn = ARGV.pop
aux_fn = ARGV.pop

raise "Please specify an aux file" unless aux_fn
raise "Please specify a bib file" unless bib_fn

unless ENV['CROSSREF_EMAIL']
  if options[:email]
    Serrano.configuration { |config| config.mailto = options[:email] }
  else
    puts "Please specifiy an email address to be nice to CrossRef."
    puts "You can do this using either the '-e' flag or setting the CROSSREF_EMAIL environmental variable."
  end
end

if options[:verbose]
  puts "Aux file = #{aux_fn}"
  puts "BibTeX file = #{bib_fn}"
end

dois = []
others = []

IGNORE_KEYS = [ 'biblatex-control' ]

# open aux file
File.open(aux_fn).each do |line|
  if line =~ /^\\citation{(.*)}$/
    key = $1
    if key =~ /^doi:(.*)/
      dois.push $1
    elsif not IGNORE_KEYS.include? key
      others.push key
    end
  end
end

# open bibtex file
bibtex = BibTeX.open(bib_fn)
bib_keys = bibtex.collect{ |b| b.key }

if options[:verbose]
  puts "Found the following keys in the current Bibtex file:"
  bib_keys.each { |key| puts "  #{key}" }
end

missing_dois = []
dois.each do |doi|
  missing_dois.push(doi) unless bib_keys.include?("doi:#{doi}")
end

missing_other = others - bib_keys

if missing_dois.length == 0
  puts "Nothing to lookup. Huzzah!" if options[:verbose]
  exit
else
  if options[:verbose]
    puts "Looking up #{missing_dois.length} DOIs:"
    missing_dois.each { |doi| puts "  #{doi}" }
  end
end

puts "Saving to backup file: #{options[:backup]}" if options[:verbose]
File.open(options[:backup], 'w') { |file| file.write(bibtex) } if options[:backup]

works = Serrano.content_negotiation(ids: missing_dois)
works = works.join('\n') if missing_dois.length > 1
bibs = BibTeX.parse(works)

bibs.each do |bib|
  idx = missing_dois.map(&:downcase).index(bib['doi'])
  if idx
    bib.key = "doi:#{missing_dois[idx]}"
    bib.delete(:url) unless options[:url]
    missing_dois.delete_at idx
    bibtex << bib
  end
end

out_fn = options[:outfile] || bib_fn
puts "Writing output to #{out_fn}" if options[:verbose]

File.open(out_fn, 'w') { |file| file.write bibtex }

if missing_dois.length > 0
  puts "Couldn't find entires for the following DOIs:"
  missing_dois.each { |doi| puts "  #{doi}" }
end

#doi_bib = missing_dois.map do |doi|
#  work = Serrano.content_negotiation(ids: doi)
#end
#
#puts doi_bib
