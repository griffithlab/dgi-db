module Genome; module Importers; module TsvImporters;
  class Talc < Genome::Importers::Base
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'TALC'
    end

    def create_claims
      create_interaction_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url: 'https://www.ncbi.nlm.nih.gov/pubmed/24377743',
          site_url: 'https://www.ncbi.nlm.nih.gov/pubmed/24377743',
          citation: "A tabulated summary of targeted and biologic therapies for non-small-cell lung cancer. Simon GR, Somaiah N. Clin Lung Cancer. 2014 Jan;15(1):21-51. doi: 10.1016/j.cllc.2013.11.009. Epub 2013 Nov 21. PMID: 24377743",
          source_db_version:  '12-May-2016',
          source_trust_level_id:  DataModel::SourceTrustLevel.EXPERT_CURATED,
          source_db_name: source_db_name,
          full_name: 'Targeted Agents in Lung Cancer (Commentary, 2014)',
          license: 'Data extracted from tables in Elsevier copyright publication',
          license_link: 'https://www.sciencedirect.com/science/article/pii/S1525730413002350',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        gene_claim = create_gene_claim(row['gene_target'], 'Gene Symbol')
        create_gene_claim_alias(gene_claim, row['gene_target'], 'Gene Symbol')
        create_gene_claim_alias(gene_claim, row['entrez_id'], 'Entrez ID')

        drug_claim = create_drug_claim(row['drug_name'].upcase, row['drug_name'].upcase, 'TALC')
        create_drug_claim_alias(drug_claim, row['drug_name'], 'Primary Drug Name')
        create_drug_claim_alias(drug_claim, row['drug_generic_name'], 'Drug Generic Name') unless row['drug_generic_name'] == 'NA'
        create_drug_claim_alias(drug_claim, row['drug_trade_name'], 'Drug Trade Name') unless row['drug_trade_name'] == 'NA'
        create_drug_claim_alias(drug_claim, row['drug_synonym'], 'Drug Synonym') unless row['drug_synonym'] == 'NA'

        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        create_interaction_claim_type(interaction_claim, row['interaction_type']) unless row['interaction_type'] == 'NA'
        create_interaction_claim_link(interaction_claim, source.citation, "https://www.sciencedirect.com/science/article/pii/S1525730413002350")
      end
    end
  end
end; end; end;
