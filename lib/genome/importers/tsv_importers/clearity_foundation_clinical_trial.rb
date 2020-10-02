module Genome; module Importers; module TsvImporters;
class ClearityFoundationClinicalTrial < Genome::Importers::Base
  attr_reader :file_path

  def initialize(file_path)
    @file_path = file_path
    @source_db_name = 'ClearityFoundationClinicalTrial'
  end

  def get_version
    source_db_version = Date.today.strftime("%d-%B-%Y")
    @new_version = source_db_version
  end

  def create_claims
    create_interaction_claims
  end

  private
  def create_new_source
    @source ||= DataModel::Source.create(
      {
          base_url: 'https://www.clearityfoundation.org/form/findtrials.aspx',
          citation: 'https://www.clearityfoundation.org/form/findtrials.aspx',
          site_url: 'https://www.clearityfoundation.org/form/findtrials.aspx',
          source_db_version: '15-June-2013',
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
          source_db_name: source_db_name,
          full_name: 'Clearity Foundation Clinical Trial',
          license: 'Unknown; data is no longer publicly available from site',
          license_link: 'https://www.clearityfoundation.org/about-clearity/contact/',
      }
    )
    @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
    @source.save
  end

  def create_interaction_claims
    CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
      gene_claim = create_gene_claim(row['Entrez Gene Name'].upcase, 'Gene Target Symbol')
      create_gene_claim_alias(gene_claim, row['Enterez Gene Id'], 'Entrez Gene ID')
      create_gene_claim_attribute(gene_claim, 'Reported Genome Event Targeted', row['Molecular Target'])

      drug_claim = create_drug_claim(row['Pubchem name'].upcase, row['Pubchem name'].upcase, 'Primary Drug Name')
      create_drug_claim_alias(drug_claim, row['Drug name'], 'Drug Trade Name')
      create_drug_claim_alias(drug_claim, row['CID'], 'PubChem Drug ID') unless row['CID'] == 'N/A'
      create_drug_claim_alias(drug_claim, row['SID'], 'PubChem Drug SID') unless row['SID'] == 'N/A'
      create_drug_claim_alias(drug_claim, row['Other drug name'], 'Other Drug Name') unless row['Other drug name'] == 'N/A'
      create_drug_claim_attribute(drug_claim, 'Clinical Trial ID', row['Clinical Trial ID(s)'])

      interaction_claim = create_interaction_claim(gene_claim, drug_claim)
      create_interaction_claim_attribute(interaction_claim, 'Mechanism of Interaction', row['Mode of action'])
      if row['Interaction type'] == 'HIF-1alpha'
        create_interaction_claim_type(interaction_claim, 'inhibitor')
      else
        create_interaction_claim_type(interaction_claim, row['Interaction type'])
      end
      create_interaction_claim_link(interaction_claim, 'Source TSV', File.join('data', 'source_tsvs', 'ClearityFoundationClinicalTrials_INTERACTIONS.tsv'))
    end
  end
end
end; end; end
