require 'net/http'
require 'genome/online_updater'

module Genome; module OnlineUpdaters; module DTC
  class Updater < Genome::OnlineUpdater
    attr_reader :new_version
    def initialize(source_db_version = Date.today.strftime("%d-%B-%Y"))
      @new_version = source_db_version
    end

    def update
      remove_existing_source
      create_new_source
      create_interaction_claims
    end

    private
    def create_interaction_claims
      api_client = ApiClient.new
      offset = 0
      limit = 500
      data = api_client.interactions(offset, limit)
      create_interaction_claims_for_data(data)
      while !data['meta']['next'].nil? do
        offset += limit
        data = api_client.interactions(offset, limit)
        create_interaction_claims_for_data(data)
      end
      backfill_publication_information()
    end

    def create_interaction_claims_for_data(data)
      data['bioactivities'].each do |entry|
        drug_id = entry['chembl_id']
        drug_name = entry['compound_name']
        gene_name = entry['gene_name']
        pmid = entry['pubmed_id']
        mechanism = entry['endpoint_actionmode']
        unless drug_name.nil? || gene_name.nil?
          drug_claim = create_drug_claim(drug_name, drug_name, 'DTC Drug Name')
          unless drug_id.nil? || drug_id == ""
            create_drug_claim_alias(drug_claim, drug_id, 'ChEMBL Drug ID')
          end
          gene_name.split(',').each do |indv_gene|
            gene_claim = create_gene_claim(indv_gene, 'DTC Gene Name')
            unless entry['uniprot_id'].nil? || entry['uniprot_id'] == ""
              create_gene_claim_alias(gene_claim, entry['uniprot_id'], 'Uniprot ID')
            end
            interaction_claim = create_interaction_claim(gene_claim, drug_claim)
            unless pmid.nil? || pmid == '""' || pmid == "''" || pmid[0] =='-' || pmid =='15288657'
              create_interaction_claim_publication(interaction_claim, pmid)
            end
            unless mechanism.nil? || mechanism == ""
              create_interaction_claim_type(interaction_claim, mechanism)
            end
            create_interaction_claim_link(interaction_claim, 'Drug Target Commons Interactions', 'https://drugtargetcommons.fimm.fi/')
          end
        end
      end
    end

    def remove_existing_source
      Utils::Database.delete_source('DTC')
    end

    def create_new_source
      @source ||= DataModel::Source.create(
          {
              base_url: 'https://drugtargetcommons.fimm.fi/',
              site_url: 'https://drugtargetcommons.fimm.fi/',
              citation: 'Drug Target Commons 2.0: a community platform for systematic analysis of drug–target interaction profiles. Tanoli Z, Alam Z, Vähä-Koskela M, Malyutina A, Jaiswal A, Tang J, Wennerberg K, Aittokallio T. Database. 2018.',
              source_db_version:  new_version,
              source_type_id: DataModel::SourceType.INTERACTION,
              source_db_name: 'DTC',
              full_name: 'Drug Target Commons',
              license: 'Creative Commons Attribution-NonCommercial 3.0 (BY-NC)',
              license_link: 'https://academic.oup.com/database/article/doi/10.1093/database/bay083/5096727',
          }
      )
    end
  end
end; end; end
