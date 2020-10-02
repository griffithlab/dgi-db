require 'zip'

class UpdateDrugBank < TsvUpdater
  def tempfile_name
    ['drugbank', '.tsv']
  end

  def create_importer
    Genome::Importers::TsvImporters::DrugBank::DrugBank.new(tempfile)
  end

  def download_file
    user = ENV["DRUGBANK_USERNAME"] || Rails.application.secrets.drugbank_username
    if user.nil?
      raise StandardException.new("Drugbank username not set")
    end
    password = ENV["DRUGBANK_PASSWORD"] || Rails.application.secrets.drugbank_password
    if password.nil?
      raise StandardException.new("Drugbank password not set")
    end
    system("DRUGBANK_USERNAME=#{user}", "DRUGBANK_PASSWORD=#{password}", "python", "lib/genome/importers/tsv_importers/drug_bank/get_drugbank.py", temp_path, tempfile.path)
  end

  def should_group_genes?
    true
  end

  def should_group_drugs?
    true
  end
end
