module Genome; module Importers; module TsvImporters;
  class TdgClinicalTrial < Genome::Importers::Base
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'TdgClinicalTrial'
    end

    def create_claims
      create_interaction_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url:          'https://clinicaltrials.gov/ct2/results?Search=Search&term=',
          site_url:          'http://www.ncbi.nlm.nih.gov/pubmed/24016212',
          citation:          "The druggable genome: Evaluation of drug targets in clinical trials suggests major shifts in molecular class and indication. Rask-Andersen M, Masuram S, Schioth HB. Annu Rev Pharmacol Toxicol. 2014;54:9-26. doi: 10.1146/annurev-pharmtox-011613-135943. PMID: 24016212",
          source_db_version:  'Jan-2014',
          source_type_id:    DataModel::SourceType.INTERACTION,
          source_db_name:    source_db_name,
          full_name:         'The Druggable Genome: Evaluation of Drug Targets in Clinical Trials Suggests Major Shifts in Molecular Class and Indication (Rask-Andersen, Masuram, Schioth 2014)',
          license: 'Supplementary table from Annual Reviews copyright publication',
          license_link: 'https://www.annualreviews.org/doi/10.1146/annurev-pharmtox-011613-135943?url_ver=Z39.88-2003&rfr_id=ori%3Arid%3Acrossref.org&rfr_dat=cr_pub++0pubmed',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        gene_claim = create_gene_claim(row['Uniprot Accession number'], 'Uniprot Accession')
        create_gene_claim_alias(gene_claim, row['Gene'], 'Gene Symbol')
        create_gene_claim_attribute(gene_claim, 'Target Class', row['Target main class']) unless row['Target main class'].blank?
        row['Target class'].split(';').each do |subclass|
          create_gene_claim_attribute(gene_claim, 'Target Subclass', subclass)
        end

        drug_claim = create_drug_claim(row['Drug Name'].upcase, row['Drug Name'].upcase, 'Drug Name')
        row['Indication(s)'].gsub('"', '').split(',').each do |indication|
          create_drug_claim_attribute(drug_claim, 'Drug Indications', indication)
        end
        create_drug_claim_attribute(drug_claim, 'Drug Class', row['Drug Class'])
        create_drug_claim_attribute(drug_claim, 'FDA Approval', row['Year of Approval (FDA)'])

        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        create_interaction_claim_attribute(interaction_claim, 'Trial Name', row['Trial name'])
        create_interaction_claim_attribute(interaction_claim, 'Novel drug target', row['Target_Novelty_VALIDATED'])
        create_interaction_claim_link(interaction_claim, source.citation, "https://www.annualreviews.org/doi/10.1146/annurev-pharmtox-011613-135943")
      end
    end
  end
end; end; end;
