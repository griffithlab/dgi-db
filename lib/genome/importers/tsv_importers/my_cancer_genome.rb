module Genome; module Importers; module TsvImporters;
  class MyCancerGenome < Genome::Importers::Base
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'MyCancerGenome'
    end

    def create_claims
      create_interaction_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url: 'https://www.mycancergenome.org/content/molecular-medicine/overview-of-targeted-therapies-for-cancer/',
          site_url: 'http://www.mycancergenome.org/',
          citation: 'Abramson, R., Aston, J., C. Lovly. 2017. My Cancer Genome.',
          source_db_version: '20-Jun-2017',
          source_db_name: source_db_name,
          full_name: 'My Cancer Genome',
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
          license: 'Restrictive, custom, non-commercial',
          license_link: 'https://www.mycancergenome.org/content/page/legal-policies-licensing/',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        gene_claim = create_gene_claim(row['Gene Symbol'], 'MyCancerGenome Gene Symbol')
        create_gene_claim_alias(gene_claim, row['Entrez Gene Id'], 'Entrez Gene Id')
        create_gene_claim_alias(gene_claim, row['Gene Symbol'], 'MyCancerGenome Gene Symbol')
        create_gene_claim_alias(gene_claim, row['Reported Gene Name'], 'MyCancerGenome Reported Gene Name')

        drug_claim = create_drug_claim(row['Primary Drug Name'].upcase, row['Primary Drug Name'].upcase, 'MyCancerGenome Drug Name')
        create_drug_claim_alias(drug_claim, row['Drug Development Name'].upcase, 'Development Name') unless row['Drug Development Name'].blank?
        create_drug_claim_alias(drug_claim, row['Drug Generic Name'].upcase, 'Generic Name') unless row['Drug Generic Name'].blank?
        create_drug_claim_alias(drug_claim, row['Drug Trade Name'].upcase, 'Trade Name') unless row['Drug Trade Name'].blank?
        create_drug_claim_attribute(drug_claim, 'Drug Class', row['Drug Class'])
        create_drug_claim_attribute(drug_claim, 'Notes', row['Notes']) unless row['Notes'].blank?

        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        create_interaction_claim_type(interaction_claim, row['Interaction Type'])
        create_interaction_claim_link(interaction_claim, 'Overview of Targeted Therapies for Cancer', "https://www.mycancergenome.org/content/page/overview-of-targeted-therapies-for-cancer/")
      end
    end
  end
end; end; end;
