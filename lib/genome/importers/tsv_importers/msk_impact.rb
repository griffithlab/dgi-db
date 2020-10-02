module Genome; module Importers; module TsvImporters;
  class MskImpact < Genome::Importers::Base
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'MskImpact'
    end

    def create_claims
      create_gene_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
            base_url: 'http://www.ncbi.nlm.nih.gov/pubmed/25801821',
            site_url: 'https://www.mskcc.org/msk-impact',
            citation: 'Memorial Sloan Kettering-Integrated Mutation Profiling of Actionable Cancer Targets (MSK-IMPACT): A Hybridization Capture-Based Next-Generation Sequencing Clinical Assay for Solid Tumor Molecular Oncology. Cheng, Donavan T., et al. The Journal of Molecular Diagnostics 17.3 (2015): 251-264. PMID: 25801821',
            source_db_version: 'May-2015',
            source_db_name: source_db_name,
            full_name: 'Memorial Sloan Kettering IMPACT',
            source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
            license: 'Supplementary data from American Society for Investigative Pathology and the Association for Molecular Pathology copyright publication',
            license_link: 'https://jmd.amjpathol.org/action/showPdf?pii=S1525-1578%2815%2900045-8',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end

    def create_gene_claims
      CSV.foreach(file_path, :headers => true) do |row|
        gene_claim = create_gene_claim(row['gene_symbol'], 'Gene Symbol')
        create_gene_claim_category(gene_claim, 'CLINICALLY ACTIONABLE')
      end
    end
  end
end; end; end;
