module Genome; module Importers
  class Base
    attr_reader :source, :source_db_name

    def import
      remove_existing_source
      create_new_source
      create_claims
    end

    def remove_existing_source
      Utils::Database.delete_source(source_db_name)
    end

    def create_new_source
      raise StandardError.new('Must implement #create_new_source in subclass')
    end

    def create_claims
      raise StandardError.new('Must implement #create_claims in subclass')
    end

    def create_gene_claim(gene_name, nomenclature)
      DataModel::GeneClaim.where(
        name: gene_name.strip(),
        nomenclature: nomenclature.strip(),
        source_id: @source.id
      ).first_or_create
    end

    def create_gene_claim_alias(gene_claim, synonym, nomenclature)
      DataModel::GeneClaimAlias.where(
        alias: synonym.to_s.strip(),
        nomenclature: nomenclature.strip(),
        gene_claim_id: gene_claim.id,
      ).first_or_create
    end

    def create_gene_claim_attribute(gene_claim, name, value)
      DataModel::GeneClaimAttribute.where(
        name: name.strip(),
        value: value.strip(),
        gene_claim_id: gene_claim.id,
      ).first_or_create
    end

    def create_gene_claim_category(gene_claim, category)
      gene_category = DataModel::GeneClaimCategory.find_by(name: category)
      if gene_category.nil?
        raise StandardError.new("GeneClaimCategory with name #{category} does not exist. If this is a valid category, please create its database entry manually before running the importer.")
      else
        gene_claim.gene_claim_categories << gene_category unless gene_claim.gene_claim_categories.include? gene_category
      end
    end

    def create_drug_claim(name, primary_name, nomenclature, source=@source)
      DataModel::DrugClaim.where(
        name: name.strip(),
        primary_name: primary_name.strip(),
        nomenclature: nomenclature.strip(),
        source_id: source.id,
      ).first_or_create
    end

    def create_drug_claim_alias(drug_claim, synonym, nomenclature)
      cleaned = synonym.gsub(/[^\w_]+/,'').upcase
      return nil unless DataModel::DrugAliasBlacklist.find_by(alias: cleaned).nil?
      DataModel::DrugClaimAlias.where(
        alias: synonym.strip(),
        nomenclature: nomenclature.strip(),
        drug_claim_id: drug_claim.id,
      ).first_or_create
    end

    def create_drug_claim_attribute(drug_claim, name, value)
      DataModel::DrugClaimAttribute.where(
        name: name.strip(),
        value: value.strip(),
        drug_claim_id: drug_claim.id
      ).first_or_create
    end

    def create_interaction_claim(gene_claim, drug_claim)
      DataModel::InteractionClaim.where(
        gene_claim_id: gene_claim.id,
        drug_claim_id: drug_claim.id,
        source_id: @source.id
      ).first_or_create
    end

    def create_interaction_claim_type(interaction_claim, type)
      claim_type = DataModel::InteractionClaimType.find_by(
        type: Genome::Normalizers::InteractionClaimType.name_normalizer(type.strip())
      )
      if claim_type.nil?
        raise StandardError.new("InteractionClaimType with type #{type} does not exist. If this is a valid type, please create its database entry manually before running the importer.")
      else
        interaction_claim.interaction_claim_types << claim_type unless interaction_claim.interaction_claim_types.include? claim_type
      end
    end

    def create_interaction_claim_publication(interaction_claim, pmid)
      publication = DataModel::Publication.where(
        pmid: pmid
      ).first_or_create
      interaction_claim.publications << publication unless interaction_claim.publications.include? publication
    end

    def create_interaction_claim_publication_by_pmcid(interaction_claim, pmcid)
      uri = URI.parse("https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/?ids=#{pmcid}&format=json&tool=DGIdb&email=help@dgidb.org")
      response_body = PMID.make_get_request(uri)
      pmid = JSON.parse(response_body)['records'][0]['pmid']
      if !pmid.nil?
        create_interaction_claim_publication(interaction_claim, pmid)
      end
    end

    def backfill_publication_information
      DataModel::Publication.where(citation: nil).find_in_batches(batch_size: 100) do |publications|
        PMID.get_citations_from_publications(publications).each do |publication, citation|
          publication.citation = citation
          publication.save
        end
        sleep(0.3)
      end
      DataModel::Publication.where(citation: "").each do |publication|
        publication.destroy
      end
    end

    def create_interaction_claim_attribute(interaction_claim, name, value)
      DataModel::InteractionClaimAttribute.where(
        name: name.to_s.strip(),
        value: value.strip(),
        interaction_claim_id: interaction_claim.id
      ).first_or_create
    end

    def create_interaction_claim_link(interaction_claim, link_text, link_url)
      DataModel::InteractionClaimLink.where(
        interaction_claim_id: interaction_claim.id,
        link_text: link_text,
        link_url: link_url,
      ).first_or_create
    end
  end
end; end
