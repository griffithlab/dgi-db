module Genome; module Importers; module TsvImporters;
  class MyCancerGenomeClinicalTrial < Genome::Importers::Base
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'MyCancerGenomeClinicalTrial'
    end

    def create_claims
      create_interaction_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url: 'http://www.mycancergenome.org/',
          citation: 'http://www.mycancergenome.org/',
          site_url: 'http://www.mycancergenome.org/',
          source_db_version: '30-Feburary-2014',
          source_type_id: DataModel::SourceType.INTERACTION,
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
          source_db_name: source_db_name,
          full_name: 'MyCancerGenome Clinical Trial',
          license: 'Restrictive, custom, non-commercial',
          license_link: 'https://www.mycancergenome.org/content/page/legal-policies-licensing/',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        next if row['Entrez gene name'] == 'N/A' or row['pubchem drug name'] == 'N/A'

        gene_claim = create_gene_claim(row['Entrez gene name'].upcase, 'Gene Target Symbol')
        create_gene_claim_alias(gene_claim, row['Gene ID'], 'Entrez Gene ID') unless row['Gene ID'] == 'N/A'
        create_gene_claim_attribute(gene_claim, 'Reported Genome Event Targeted', row['genes']) unless row['genes'] == 'N/A'

        drug_claim = create_drug_claim(row['pubchem drug name'].upcase, row['pubchem drug name'].upcase, 'Primary Drug Name')
        create_drug_claim_alias(drug_claim, row['Drug name'], 'Drug Trade Name') unless row['Drug name'] == 'N/A'
        create_drug_claim_alias(drug_claim, row['pubchem drug id'], 'PubChem Drug ID') unless row['pubchem drug id'] == 'N/A'
        create_drug_claim_alias(drug_claim, row['Other drug names'], 'Other Drug Name') unless row['Other drug names'] == 'N/A'

        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        create_interaction_claim_type(interaction_claim, row['Interaction type'])
        create_interaction_claim_attribute(interaction_claim, 'Clinical Trial ID', row['clinical trial ID']) unless row['clinical trial ID'] == 'N/A'
        create_interaction_claim_attribute(interaction_claim, 'Type of Cancer Targeted', row['Disease'])
        create_interaction_claim_attribute(interaction_claim, 'Indication of Interaction', row['indication of drug-gene interaction']) unless row['indication of drug-gene interaction'] == 'N/A'
        create_interaction_claim_link(interaction_claim, 'Clinical Trials', "https://www.mycancergenome.org/content/clinical_trials/")
      end
    end
  end
end; end; end;
