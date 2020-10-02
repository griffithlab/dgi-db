class UpdateEntrez < TsvUpdater
  def tempfile_name
    ['entrez_download', '.gz']
  end

  def create_importer
    Genome::Importers::TsvImporters::Entrez.new(tempfile)
  end

  def latest_url
    "ftp://ftp.ncbi.nih.gov/gene/DATA/GENE_INFO/Mammalia/Homo_sapiens.gene_info.gz"
  end

  def should_group_genes?
    true
  end

  def should_group_drugs?
    false
  end

  def should_cleanup_gene_claims?
    true
  end
end
