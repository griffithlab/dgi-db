require 'net/http'

module Genome; module Importers; module ApiImporters; module Civic
  class Importer < Genome::Importers::Base
    attr_reader :new_version
    def initialize(source_db_version = Date.today.strftime("%d-%B-%Y"))
      @new_version = source_db_version
      @source_db_name = 'CIViC'
    end

    def create_claims
      create_interaction_claims
    end

    private
    def create_interaction_claims
      api_client = ApiClient.new
      api_client.variants.each do |variant|
        api_client.evidence_items_for_variant(variant['id']).select { |ei| importable_eid?(ei) }.each do |ei|
          create_entries_for_evidence_item(variant, ei)
        end
      end
      backfill_publication_information()
    end

    def importable_eid?(evidence_item)
      [
        evidence_item['evidence_type'] == 'Predictive',
        evidence_item['evidence_direction'] == 'Supports',
        evidence_item['evidence_level'] != 'E',
        evidence_item['rating'].present? && evidence_item['rating'] > 2
      ].all?
    end

    def create_entries_for_evidence_item(variant, ei)
      ei['drugs'].select { |d| valid_drug?(d) }.each do |drug|
        gc = create_gene_claim(variant['entrez_name'], 'Entrez Gene Symbol')
        create_gene_claim_aliases(gc, variant)
        if ei['clinical_significance'] == 'Resistance'
          create_gene_claim_category(gc, "DRUG RESISTANCE")
        end
        if ei['evidence_level'] == 'A'
          create_gene_claim_category(gc, "CLINICALLY ACTIONABLE")
        end
        dc = create_drug_claim(drug['name'].upcase, drug['name'].upcase, 'CIViC Drug Name')
        ic = create_interaction_claim(gc, dc)
        if ei['source']['citation_id'].present? and ei['source']['source_type'] == 'PubMed'
          create_interaction_claim_publication(ic, ei['source']['citation_id'])
        end
        create_interaction_claim_type(ic, 'n/a')
        create_interaction_claim_link(ic, ei['name'], "https://civicdb.org/links/evidence/#{ei['id']}")
      end
    end

    def valid_drug?(drug)
      [
        drug['name'].upcase != 'N/A',
        !drug['name'].include?(';'),
      ].all?
    end

    def create_gene_claim_aliases(gc, variant)
      create_gene_claim_alias(gc, variant['entrez_id'].to_s, 'Entrez Gene ID')
      create_gene_claim_alias(gc, variant['gene_id'].to_s, 'CIViC Gene ID')
    end

    def create_new_source
      @source ||= DataModel::Source.create(
        {
          source_db_name: source_db_name,
          source_db_version: new_version,
          base_url: 'https://www.civicdb.org',
          site_url: 'https://www.civicdb.org',
          citation: 'Griffith M*, Spies NC*, Krysiak K*, McMichael JF, Coffman AC, Danos AM, Ainscough BJ, Ramirez CA, Rieke DT, Kujan L, Barnell EK, Wagner AH, Skidmore ZL, Wollam A, Liu CJ, Jones MR, Bilski RL, Lesurf R, Feng YY, Shah NM, Bonakdar M, Trani L, Matlock M, Ramu A, Campbell KM, Spies GC, Graubert AP, Gangavarapu K, Eldred JM, Larson DE, Walker JR, Good BM, Wu C, Su AI, Dienstmann R, Margolin AA, Tamborero D, Lopez-Bigas N, Jones SJ, Bose R, Spencer DH Wartman LD, Wilson RK, Mardis ER, Griffith OL†. 2016. CIViC is a community knowledgebase for expert crowdsourcing the clinical interpretation of variants in cancer. Nat Genet. 49, 170–174 (2017); doi: doi.org/10.1038/ng.3774. PMID: 28138153',
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
          full_name: 'CIViC: Clinical Interpretation of Variants in Cancer',
          license: 'Creative Commons Public Domain Dedication (CC0 1.0 Universal)',
          license_link: 'https://docs.civicdb.org/en/latest/about/faq.html#how-is-civic-licensed',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end
  end
end; end; end; end
