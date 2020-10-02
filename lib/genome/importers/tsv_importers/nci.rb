module Genome; module Importers; module TsvImporters
  class Nci < Genome::Importers::Base
    attr_reader :file_path
    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'NCI'
    end

    def get_version
      source_db_version = Date.today.strftime('%d-%B-%Y')
      @new_version = source_db_version
    end

    def create_claims
      create_interaction_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
          {
              base_url: 'https://wiki.nci.nih.gov/display/cageneindex/The+Cancer+Gene+Index+Gene-Disease+and+Gene-Compound+XML+Documents',
              site_url: 'https://wiki.nci.nih.gov/display/cageneindex',
              citation: 'https://wiki.nci.nih.gov/display/cageneindex',
              source_db_version:  get_version,
              source_db_name: source_db_name,
              full_name: 'NCI Cancer Gene Index',
              license: 'Public domain',
              license_link: 'https://www.cancer.gov/policies/copyright-reuse',
          }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      CSV.foreach(file_path, encoding:'iso-8859-1:utf-8', :headers => true, :col_sep => "\t") do |row|
        gene_claim = create_gene_claim(row['Gene'], 'CGI Gene Name')
        drug = row['Drug'].upcase
        drug_claim = create_drug_claim(drug, drug, 'NCI Drug Name')
        create_drug_claim_alias(drug_claim, row['NCI drug code'], 'NCI drug code')
        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        create_interaction_claim_publication(interaction_claim, row['PMID'])
        create_interaction_claim_link(interaction_claim, "The Cancer Gene Index Gene-Disease and Gene-Compound XML Documents", 'https://wiki.nci.nih.gov/display/cageneindex/The+Cancer+Gene+Index+Gene-Disease+and+Gene-Compound+XML+Documents')
      end
      backfill_publication_information()
    end
  end
end; end; end
