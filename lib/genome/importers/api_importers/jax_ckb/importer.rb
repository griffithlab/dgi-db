module Genome; module Importers; module ApiImporters; module JaxCkb;
  class Importer < Genome::Importers::Base
    attr_reader :new_version
    def initialize(source_db_version = Date.today.strftime("%d-%B-%Y"))
      @new_version = source_db_version
      @source_db_name = 'JAX-CKB'
    end

    def create_claims
      create_interaction_claims
    end

    def create_new_source
      @source ||= DataModel::Source.create(
        {
          source_db_name: source_db_name,
          source_db_version: new_version,
          base_url: 'https://ckb.jax.org/gene/show?geneId=',
          site_url: 'https://ckb.jax.org',
          citation: 'Sara E. Patterson, Rangjiao Liu, Cara M. Statz, Daniel Durkin, Anuradha Lakshminarayana, and Susan M. Mockus. The Clinical Trial Landscape in Oncology and Connectivity of Somatic Mutational Profiles to Targeted Therapies. Human Genomics, 2016 Jan 16;10(1):4. PMID: 26772741',
          full_name: 'The Jackson Laboratory Clinical Knowledgebase',
          license: 'Creative Commons Attribution-NonCommercial-ShareAlike 4.0 International License',
          license_link: 'https://ckb.jax.org/about/index',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      api_client = ApiClient.new
      api_client.genes.each do |gene|
        gene_claim = create_gene_claim(gene['geneName'], 'CKB Gene Name')
        create_gene_claim_aliases(gene_claim, gene)
        api_client.interactions_for_gene_id(gene['id']).each do |interaction|
          drug_name = interaction['Therapy Name']
          if drug_name.include? '+'
            combination_drug_name = drug_name
            combination_drug_name.split(' + ').each do |individual_drug_name|
              drug_claim = create_drug_claim(individual_drug_name, individual_drug_name, 'CKB Drug Name')
              interaction_claim = create_interaction_claim(gene_claim, drug_claim)
              create_interaction_claim_attribute(interaction_claim, 'combination therapy', combination_drug_name)
              create_interaction_claim_publications(interaction_claim, interaction['References'])
              create_interaction_claim_attributes(interaction_claim, interaction)
              create_interaction_claim_link(interaction_claim, "#{gene['geneName']} Gene Level Evidence", "https://ckb.jax.org/gene/show?geneId=#{gene['id']}&tabType=GENE_LEVEL_EVIDENCE")
            end
          else
            drug_claim = create_drug_claim(drug_name, drug_name, 'CKB Drug Name')
            interaction_claim = create_interaction_claim(gene_claim, drug_claim)
            create_interaction_claim_publications(interaction_claim, interaction['References'])
            create_interaction_claim_attributes(interaction_claim, interaction)
            create_interaction_claim_link(interaction_claim, "#{gene['geneName']} Gene Level Evidence", "https://ckb.jax.org/gene/show?geneId=#{gene['id']}&tabType=GENE_LEVEL_EVIDENCE")
          end
        end
      end
      backfill_publication_information()
    end

    def create_gene_claim_aliases(gene_claim, gene)
      create_gene_claim_alias(gene_claim, gene['id'], 'CKB Entrez Id')
      gene['text'].split(' | ').each do |synonym|
        create_gene_claim_alias(gene_claim, synonym, 'CKB Gene Synonym')
      end
    end

    def create_interaction_claim_publications(interaction_claim, publications)
      publications.split.select { |p| valid_pmid?(p) }.each do |pmid|
        if pmid == '30715168'
          pmid = '31987360'
        end
        create_interaction_claim_publication(interaction_claim, pmid)
      end
    end

    def valid_pmid?(pmid)
      pmid.to_i.to_s == pmid
    end

    def create_interaction_claim_attributes(interaction_claim, interaction)
      ['Indication/Tumor Type', 'Response Type', 'Approval Status', 'Evidence Type'].each do |name|
        create_interaction_claim_attribute(interaction_claim, name, interaction[name])
      end
    end
  end
end; end; end; end
