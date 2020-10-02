module Genome; module Importers; module ApiImporters; module Oncokb;
  class Importer < Genome::Importers::Base
    attr_reader :new_version
    def initialize(source_db_version = Date.today.strftime("%d-%B-%Y"))
      @new_version = source_db_version
      @source_db_name = 'OncoKB'
    end

    def create_claims
      create_interaction_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          source_db_name: source_db_name,
          source_db_version: new_version,
          base_url: 'http://oncokb.org/',
          site_url: 'http://oncokb.org/',
          citation: 'OncoKB: A Precision Oncology Knowledge Base. Chakravarty D, Gao J, Phillips S, et. al. JCO Precision Oncology 2017 :1, 1-16. PMID: 28890946',
          full_name: 'OncoKB: A Precision Oncology Knowledge Base',
          license: 'Restrictive, non-commercial',
          license_link: 'https://www.oncokb.org/terms',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      api_client = ApiClient.new
      genes = get_genes(api_client)
      drugs = get_drugs(api_client)
      api_client.variants.each do |variant|
        gene = genes[variant['gene']]
        gene_claim = create_gene_claim(gene['hugoSymbol'], 'OncoKB Gene Name')
        create_gene_claim_aliases(gene_claim, gene)

        variant['drugs'].split(', ').each do |drug_name|
          if drug_name.include? '+'
            combination_drug_name = drug_name
            combination_drug_name.split(' + ').each do |individual_drug_name|
              if valid_drug?(individual_drug_name)
                drug = drugs[individual_drug_name]
                drug_claim = create_drug_claim(drug['drugName'], drug['drugName'], 'OncoKB Drug Name')
                interaction_claim = create_interaction_claim(gene_claim, drug_claim)
                create_interaction_claim_attribute(interaction_claim, 'combination therapy', combination_drug_name)
                #Our current agreement with OncoKB precludes us from importing the associated PMIDs
                #add_interaction_claim_publications(interaction_claim, variant['pmids'])
                create_interaction_claim_link(interaction_claim, "#{gene['hugoSymbol']} Clinically Relevant Alterations", "https://www.oncokb.org/gene/#{gene['hugoSymbol']}")
              end
            end
          else
            if valid_drug?(drug_name)
              drug = drugs[drug_name]
              drug_claim = create_drug_claim(drug['drugName'], drug['drugName'], 'OncoKB Drug Name')
              interaction_claim = create_interaction_claim(gene_claim, drug_claim)
              #Our current agreement with OncoKB precludes us from importing the associated PMIDs
              #add_interaction_claim_publications(interaction_claim, variant['pmids'])
              create_interaction_claim_link(interaction_claim, "#{gene['hugoSymbol']} Clinically Relevant Alterations", "https://www.oncokb.org/gene/#{gene['hugoSymbol']}")
            end
          end
        end
      end
    end

    def get_genes(api_client)
      api_client.genes.each_with_object({}) do |g, h|
        h[g['hugoSymbol']] = g
      end
    end

    def get_drugs(api_client)
      api_client.drugs.each_with_object({}) do |d, h|
        h[d['drugName']] = d
      end
    end

    def create_gene_claim_aliases(gene_claim, gene)
      create_gene_claim_alias(gene_claim, gene['entrezGeneId'], 'OncoKB Entrez Id')
      gene['geneAliases'].each do |synonym|
        create_gene_claim_alias(gene_claim, synonym, 'OncoKB Gene Synonym')
      end
    end

    def valid_drug?(drug_name)
      ['Radiation'].none? { |name| drug_name.include?(name)  }
    end

    def add_interaction_claim_publications(interaction_claim, pmids)
      pmids.split(', ').each do |pmid|
        create_interaction_claim_publication(interaction_claim, pmid)
      end
    end
  end
end; end; end; end
