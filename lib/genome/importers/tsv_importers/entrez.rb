#we don't always need to update entrez, if this is slow, we should do it incrementally
#which means we need to be aware of the previous version
module Genome; module Importers; module TsvImporters;
  class Entrez
    attr_reader :file_path, :source
    def initialize(file_path)
      @file_path = file_path
    end

    def import
      create_source
      import_symbols
    end

    private
    def create_source
      @source = DataModel::Source.where(
        base_url: 'http://www.ncbi.nlm.nih.gov/gene?term=',
        site_url: 'http://www.ncbi.nlm.nih.gov/gene',
        citation: 'Entrez Gene: gene-centered information at NCBI. Maglott D, Ostell J, Pruitt KD, Tatusova T. Nucleic Acids Res. 2011 Jan;39(Database issue)52-7. Epub 2010 Nov 28. PMID: 21115458.',
        source_db_name: 'Entrez',
        full_name: 'NCBI Entrez Gene',
        license: 'Unrestricted license, pass-through constraints',
        license_link: 'https://www.nlm.nih.gov/accessibility.html',
      ).first_or_initialize
      source.source_db_version = Date.today.strftime("%d-%B-%Y")
      source_type = DataModel::SourceType.find_by(type: 'gene')
      unless source.source_types.include? source_type
        source.source_types << source_type
        source.save
      end
    end

    def import_symbols
#      ActiveRecord::Base.transaction do
        File.open(file_path, 'r') do |file|
          reader = Zlib::GzipReader.new(file, encoding: "iso-8859-1:UTF-8")
          CSV.new(reader, col_sep: "\t", headers: true).each do |line|
            next unless valid_line?(line)
            process_line(line)
          end
          reader.close
        end
#      end
    end

    def valid_line?(line)
      line['GeneID'].present? &&
        line['Symbol_from_nomenclature_authority'].present? &&
        line['Symbol_from_nomenclature_authority'].strip != '-' &&
        line['#tax_id'] == '9606'
    end

    def process_line(line)
      entrez_id = line['GeneID']
      name = line['Symbol_from_nomenclature_authority'].upcase
      long_name = line['description'].upcase

      gene = DataModel::Gene.where(name: name).first
      if gene and gene.entrez_id != entrez_id
        create_alias(gene, gene.entrez_id.to_s)
        gene.entrez_id = entrez_id
      else
        gene = DataModel::Gene.where(entrez_id: entrez_id ).first_or_initialize
        gene.name = name
        gene.long_name = long_name
      end
      gene.save

      #if the name or long name has changed, we want to preserve the old name as an alias
      #if name != gene.name && gene.name.present?
        #create_alias(gene, gene.name)
      #end
      #if long_name != gene.long_name && gene.long_name.present?
        #create_alias(gene, gene.long_name)
      #end

      create_alias(gene, entrez_id)
      create_alias(gene, long_name)
      create_alias(gene, name)
      process_synonyms(gene, line['Synonyms'])
      process_ensembl(gene, line['dbXrefs'])
    end

    def create_alias(gene, name)
      if (existing_gene_alias = DataModel::GeneAlias.where(
        'gene_id = ? and upper(alias) = ?', gene.id, name.upcase
      )).any?
        gene_alias = existing_gene_alias.first
      else
        gene_alias = DataModel::GeneAlias.where(
          gene_id: gene.id,
          alias: name
        ).first_or_create
      end
      gene_alias.sources << source unless gene_alias.sources.include?(source)
    end

    def process_synonyms(gene, synonyms)
      if synonyms.present?
        synonyms.split('|').each do |synonym|
          if synonym.strip == '-'
            nil
          else
            create_alias(gene, synonym)
          end
        end
      end
    end

    def process_ensembl(gene, xrefs)
      if xrefs.present?
        xrefs.split('|')
          .map { |x| x.split(':').last }
          .each { |ensembl_id| create_alias(gene, ensembl_id) }
      end
    end
  end
end; end; end
