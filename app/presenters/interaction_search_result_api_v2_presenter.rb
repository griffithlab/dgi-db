class InteractionSearchResultApiV2Presenter
  def initialize(search_result, identifier, interactions)
    @result = search_result
    @identifier = identifier
    @interactions= interactions.map{|i| InteractionWrapper.new(i)}
  end

  def identifier
    @identifier
  end

  def search_term
    @result.search_term
  end

  def type
    @result.type
  end

  def has_interactions?
    @interactions.size > 0
  end

  def interactions
    @interactions
  end

  private
  def gene
    @result.interactions
      .first
      .gene
  end

  def drug
    @result.interactions
      .first
      .drug
  end

  InteractionWrapper = Struct.new(:interaction) do
    def types
      interaction.interaction_types.map(&:type)
    end

    def types_string
      type.map(&:type)
    end

    def interaction_id
      interaction.id
    end

    def source_db_names
      interaction.sources.map(&:source_db_name)
    end

    def drug_name
      interaction.drug.name
    end

    def drug_concept_id
      interaction.drug.concept_id
    end

    def gene_name
      interaction.gene.name
    end

    def gene_long_name
      interaction.gene.long_name
    end

    def gene_entrez_id
      interaction.gene.entrez_id
    end

    def publications
      interaction.publications.map(&:pmid)
    end

    def score
      interaction.interaction_score.round(2)
    end
  end
end
