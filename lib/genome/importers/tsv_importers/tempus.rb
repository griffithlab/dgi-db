module Genome; module Importers; module TsvImporters;
  class Tempus < Genome::Importers::Base
    attr_reader :file_path

    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'Tempus'
    end

    def create_claims
      create_gene_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url:           'https://www.tempus.com/clinical-validation-of-the-tempus-xt-next-generation-targeted-oncology-sequencing-assay/',
          site_url:           'https://www.tempus.com/',
          citation:           'Beaubier, N, Tell, R, Lau, D, Parsons, JR, Bush, S, Perera, J, Sorrells, S, Baker, T, Chang, A, Michuda, J, Iguartua, C, MacNeil, S, Shah, K, Ellis, P, Yeatts, K, Mahon, B, Taxter, T, Bontrager, M, Khan, A, Huether, R, Lefkofsky, E, & White, KP. Clinical validation of the tempus xT next-generation targeted oncology sequencing assay. Oncotarget 2019 Mar 22;10(24):2384-2396. PMID: 31040929.',
          source_db_version:  '11-November-2018',
          source_trust_level_id: DataModel::SourceTrustLevel.EXPERT_CURATED,
          source_db_name:     source_db_name,
          source_db_name:     'Tempus',
          full_name:          'Tempus xT',
          license:            'Supplementary data from CC-BY 3.0 Beaubier et al. copyright publication',
          license_link:       'https://www.oncotarget.com/article/26797/text/',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end

    def create_gene_claims
      CSV.foreach(file_path, :headers => true) do |row|
        gene_claim = create_gene_claim(row['Gene'], 'Gene Symbol')
        create_gene_claim_category(gene_claim, 'CLINICALLY ACTIONABLE')
      end
    end
  end
end; end; end;
