class UpdateOncokb < ApiUpdater
  def create_importer
    Genome::Importers::ApiImporters::Oncokb::Importer.new()
  end

  def should_group_genes?
    true
  end

  def should_group_drugs?
    true
  end

  def should_cleanup_gene_claims?
    false
  end
end
