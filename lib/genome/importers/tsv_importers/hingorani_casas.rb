module Genome; module Importers; module TsvImporters;
  class HingoraniCasas < Genome::Importers::Base
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'HingoraniCasas'
    end

    def create_claims
      create_gene_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url:           'http://stm.sciencemag.org/content/9/383/eaag1166',
          site_url:           'http://stm.sciencemag.org/content/9/383/eaag1166',
          citation:           'The druggable genome and support for target identification and validation in drug development. Finan C, Gaulton A, Kurger F, Lumbers T, Shah T, Engmann J, Galver L, Kelly R, Karlsson A, Santos R, Overington J, Hingorani A, Casas JP.   Sci. Transl. Med. 2017 Mar 29;9(383):eaag1166 PMID: 28356508.',
          source_db_version:  '31-May-2017',
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
          source_db_name:     source_db_name,
          full_name:          'The druggable genome and support for target identification and validation in drug development (Hingorani & Casas, 2017)',
          license: 'Supplementary data from Author Copyright publication',
          license_link: 'https://stm.sciencemag.org/content/9/383/eaag1166/tab-pdf',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end

    def create_gene_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        unless row['hgnc_names'].blank?
          gene_claim = create_gene_claim(row['hgnc_names'], 'HingoraniCasas Gene Symbol')
          create_gene_claim_alias(gene_claim, row['hgnc_names'].upcase, 'Gene Symbol')
          create_gene_claim_alias(gene_claim, row['ensembl_gene_id'].upcase, 'Ensembl Id')
          create_gene_claim_category(gene_claim, 'DRUGGABLE GENOME')
        end
      end
    end
  end
end; end; end;
