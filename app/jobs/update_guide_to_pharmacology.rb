class UpdateGuideToPharmacology < TsvUpdater
  attr_reader :gene_tempfile, :interaction_tempfile

  def import
    begin
      create_tempfiles
      download_files
      @importer = create_importer
      importer.import
    ensure
      remove_downloads
    end
  end

  def create_tempfiles
    @gene_tempfile = Tempfile.new(gene_tempfile_name, temp_path)
    @interaction_tempfile = Tempfile.new(interaction_tempfile_name, temp_path)
  end

  def download_files
    download_stream = open(gene_url, open_timeout: 300)
    IO.copy_stream(download_stream, gene_tempfile)
    download_stream = open(interaction_url, open_timeout: 300)
    IO.copy_stream(download_stream, interaction_tempfile)
  end

  def gene_tempfile_name
    ['gene', '.tsv']
  end

  def interaction_tempfile_name
    ['interactions', '.tsv']
  end

  def create_importer
    Genome::Importers::TsvImporters::GuideToPharmacology.new(interaction_tempfile, gene_tempfile)
  end

  def interaction_url
    "https://www.guidetopharmacology.org/DATA/interactions.csv"
  end

  def gene_url
    "https://www.guidetopharmacology.org/DATA/targets_and_families.csv"
  end

  def remove_downloads
    gene_tempfile.close
    gene_tempfile.unlink
    interaction_tempfile.close
    interaction_tempfile.unlink
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
