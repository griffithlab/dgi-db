module Genome; module Importers; module TsvImporters
  class CancerCommons < Genome::Importers::Base
    attr_reader :file_path
    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'CancerCommons'
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
          base_url: 'http://www.cancercommons.org/researchers-clinicians/',
          site_url: 'http://www.cancercommons.org/',
          citation: 'Cancer Commons: Biomedicine in the Internet Age. Shrager J, Tenenbaum JM, and Travers M. Collaborative Computational Technologies for Biomedical Research, (Sean Elkins, Maggie Hupcey, and Antony Williams Eds). Wiley, 2010.',
          source_db_version: '25-Jul-2013',
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
          source_db_name: source_db_name,
          full_name: 'Cancer Commons',
          license: 'Custom non-commercial',
          license_link: 'https://www.cancercommons.org/terms-of-use/',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      CSV.foreach(file_path, encoding: 'iso-8850-1:utf-8', :headers => true, :col_sep => "\t") do |row|
        gene_claim = create_gene_claim(row['primary_gene_name'].upcase, 'Gene Target Symbol')
        create_gene_claim_alias(gene_claim, row['entrez_gene_id'], 'Entrez Gene ID')
        create_gene_claim_attribute(gene_claim, 'CancerCommons Reported Gene Name', row['reported_gene_name'])

        drug_claim = create_drug_claim(row['primary_drug_name'].strip.upcase, 'Primary Drug Name')
        create_drug_claim_attribute(drug_claim, 'Drug Class', row['drug_class'])
        create_drug_claim_attribute(drug_claim, 'Source Reported Drug Name(s)', row['source_reported_drug_name'])
        create_drug_claim_attribute(drug_claim, 'Pharmaceutical Developer', row['pharmaceutical_developer'])
        create_drug_claim_alias(drug_claim, row['pubchem_drug_name'], 'PubChem Drug Name')
        create_drug_claim_alias(drug_claim, row['pubchem_drug_id'], 'PubChem Drug ID')
        create_drug_claim_alias(drug_claim, row['drug_trade_name'], 'Drug Trade Name')
        create_drug_claim_alias(drug_claim, row['drug_development_name'], 'Drug Development Name')

        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        create_interaction_claim_type(interaction_claim, row['interaction_type'])
        create_interaction_claim_attribute(interaction_claim, 'Reported Cancer Type', row['cancer_type'])
        create_interaction_claim_link(interaction_claim, 'Source TSV', File.join('data', 'source_tsvs', 'CancerCommons_INTERACTIONS.tsv'))
      end
    end
  end
end; end; end
