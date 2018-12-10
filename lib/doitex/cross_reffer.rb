require "serrano"
require "yaml"
require "bibtex-ruby"

module Doitex
  IGNORE_KEYS = [ 'biblatex-control' ]

  class CrossReffer
    def initialize(options)
      @dois = []
      @others = []
      @missing_dois = []
      @options = options

      if options[:email]
        Serrano.configuration { |config| config.mailto = options[:email] }
      else
        puts "Please specifiy an email address to be nice to CrossRef."
        puts "You can do this using either the '-e' flag or setting the CROSSREF_EMAIL environmental variable."
      end
    end

    def load_key_map(map_fn)
      @key_map = YAML.load_file(map_fn)
    end

    def parse_aux(aux_fn)
      # open aux file
      File.open(aux_fn).each do |line|
        if line =~ /^\\citation{(.*)}$/
          keys = $1.split(/,/)
          keys.each do |key|
            if @key_map && @key_map.keys.include?(key)
              @dois.push key
            elsif key =~ /^doi:(.*)/
              @dois.push $1
            elsif not IGNORE_KEYS.include? key
              @others.push key
            end
          end
        end
      end

      @dois.uniq!
      @others.uniq!

      @dois
    end

    def parse_bibtex(bib_fn)
      # open bibtex file
      @bibtex = BibTeX.open(bib_fn)
      @bib_keys = bibtex.collect{ |b| b.key }

      if @options[:verbose]
        puts "Found the following keys in the current Bibtex file:"
        @bib_keys.each { |key| puts "  #{key}" }
      end

      @dois.each do |doi|
        if @key_map && @key_map.include?(doi)
          puts "Mapped DOI: #{doi} => #{@key_map[doi]}" if @options[:verbose]
          @missing_dois.push(@key_map[doi]) unless @bib_keys.include?(doi)
        else
          @missing_dois.push(doi) unless @bib_keys.include?("doi:#{doi}")
        end
      end
      @missing_dois.uniq!
      @missing_dois
    end

    def fetch_dois
      @works = Serrano.content_negotiation(ids: @missing_dois)
      @works = @works.join('\n') if @missing_dois.length > 1
      bibs = BibTeX.parse(@works)

      bibs.each do |bib|
        idx = @missing_dois.map(&:downcase).index(bib['doi'])
        if idx
          key = @key_map && @key_map.key(@missing_dois[idx])
          if key
            puts "Using mapped key: #{key} => #{@missing_dois[idx]}" if @options[:verbose]
            bib.key = key
          else
            bib.key = "doi:#{missing_dois[idx]}"
          end
          bib.delete(:url) unless @options[:url]
          @missing_dois.delete_at idx
          @bibtex << bib
        end
      end
    end
  end
end
