module Genome; module Importers; module TsvImporters;
  class Ensembl < Genome::Importers::Base
    attr_reader :file_path, :version
    def initialize(file_path, version)
      @file_path = file_path
      @version = version
      @source_db_name = 'Ensembl'
    end

    def create_claims
      import_symbols
    end

    private
    def create_new_source
      @source = DataModel::Source.where(
        base_url:           'http://useast.ensembl.org/Homo_sapiens/Gene/Summary?g=',
        site_url:           'http://ensembl.org/index.html',
        citation:           'Ensembl 2011. Flicek P, Amode MR, ..., Vogel J, Searle SM. Nucleic Acids Res. 2011 Jan;39(Database issue)800-6. Epub 2010 Nov 2. PMID: 21045057.',
        source_db_version:  version,
        source_db_name:     source_db_name,
        full_name:          'Ensembl',
        license: 'Unrestricted license, pass-through constraints',
        license_link:        'https://useast.ensembl.org/info/about/legal/disclaimer.html',
      ).first_or_create
      @source.source_types << DataModel::SourceType.find_by(type: 'gene')
      @source.save
    end

    def import_symbols
#      ActiveRecord::Base.transaction do
        File.open(file_path, 'r') do |file|
          reader = Zlib::GzipReader.new(file, encoding: "iso-8859-1:UTF-8")
          CSV.new(reader, col_sep: "\t", headers: headers, quote_char: "'", skip_lines: /^#!/).each do |line|
            next unless valid_line?(line)
            process_line(line)
          end
          reader.close
        end
#      end
    end

    def headers
      ['seqname', 'source', 'feature', 'start', 'end', 'score', 'strand', 'frame', 'attribute']
    end

    def valid_line?(line)
      line['feature'] == 'gene'
    end

    def process_line(line)
      attributes = line['attribute'].split(';')
      attribute_hash = {}
      attributes.each do |a|
        a = a.strip
        (key, value) = a.split(' ')
        attribute_hash[key] = value[1..-2] #Stripe quotes
      end

      gene_claim = create_gene_claim(attribute_hash['gene_id'].upcase, 'Ensembl Gene Id')
      create_gene_claim_alias(gene_claim, attribute_hash['gene_name'].upcase, 'Ensembl Gene Name')
      create_gene_claim_attribute(gene_claim, 'Gene Biotype', attribute_hash['gene_biotype'].upcase)
    end
  end
end; end; end
