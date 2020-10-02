module Genome; module Importers; module TsvImporters;
  class IDG < Genome::Importers::Base
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'IDG'
    end

    def create_claims
      create_gene_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url:           'https://druggablegenome.net/IDGProteinList/',
          site_url:           'https://druggablegenome.net/',
          citation:           'https://druggablegenome.net/',
          source_db_version:  '15-July-2019',
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
          source_db_name:     source_db_name,
          full_name:          'Illuminating the Druggable Genome',
          license:       'Creative Commons Attribution-ShareAlike 4.0 International License',
          license_link:       'https://druggablegenome.net/IDGPolicies#Policy3',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end

    def create_gene_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        gene_claim = create_gene_claim(row['Gene'], 'IDG Gene Symbol')
        create_gene_claim_alias(gene_claim, row['Gene'], 'Gene Symbol')
        if row['Category'] == 'GPCR'
          create_gene_claim_category(gene_claim, 'G PROTEIN COUPLED RECEPTOR')
        else
          create_gene_claim_category(gene_claim, row['Category'].upcase)
        end
      end
    end
  end
end; end; end;
