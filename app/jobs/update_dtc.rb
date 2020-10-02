OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class UpdateDtc < TsvUpdater
  def tempfile_name
    ['dtc_bioactivity', '.csv']
  end

  def create_importer
    Genome::Importers::TsvImporters::Dtc.new(tempfile)
  end

  def latest_url
    'https://drugtargetcommons.fimm.fi/static/Excell_files/DTC_data.csv'
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
