module Genome; module Importers; module ApiImporters; module Pharos;
  class Importer < Genome::Importers::Base
    attr_reader :new_version
    def initialize(source_db_version = Date.today.strftime("%d-%B-%Y"))
      @new_version = source_db_version
      @source_db_name = 'Pharos'
    end

    def create_claims
      create_gene_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url:           'https://pharos-api.ncats.io/graphql',
          site_url:           'https://pharos.nih.gov/',
          citation:           'Nguyen, D.-T., Mathias, S. et al, "Pharos: Collating Protein Information to Shed Light on the Druggable Genome", Nucl. Acids Res.i>, 2017, 45(D1), D995-D1002. DOI: 10.1093/nar/gkw1072. PMID: 27903890',
          source_db_version:  @new_version,
          source_db_name:     source_db_name,
          full_name:          'Pharos',
          license:            'Creative Commons Attribution-ShareAlike 4.0 International License',
          license_link:       'https://pharos.nih.gov/about',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end

    def create_gene_claims
      api_client = ApiClient.new
      categories.each do |category|
        start = 0
        count = 100
        genes = api_client.genes_for_category(category, start, count)
        while genes.size > 0
          genes.each do |gene|
            unless gene['sym'].nil?
              gene_claim = create_gene_claim(gene['sym'], 'Gene Symbol')
              create_gene_claim_alias(gene_claim, gene['name'], 'Gene Name')
              create_gene_claim_alias(gene_claim, gene['uniprot'], 'UniProt ID')
              normalized_category = case category
              when 'GPCR'
                'G PROTEIN COUPLED RECEPTOR'
              when 'Nuclear Receptor'
                'NUCLEAR HORMONE RECEPTOR'
              else
                category.upcase
              end
              create_gene_claim_category(gene_claim, normalized_category)
            end
          end
          start += count
          genes = api_client.genes_for_category(category, start, count)
        end
      end
    end

    def categories
      [ "Enzyme", "Transcription Factor", "Kinase", "Transporter", "GPCR", "Ion Channel", "Nuclear Receptor" ]
    end
  end
end; end; end; end
