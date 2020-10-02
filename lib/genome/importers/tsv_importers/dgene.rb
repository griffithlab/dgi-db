module Genome; module Importers; module TsvImporters;
  class DGene < Genome::Importers::Base
    attr_reader :file_path
    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'dGene'
    end

    def create_claims
      create_gene_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
          {
              base_url:          'http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0067980',
              site_url:          'http://journals.plos.org/plosone/article?id=10.1371/journal.pone.0067980',
              citation:          'Prioritizing Potentially Druggable Mutations with dGene: An Annotation Tool for Cancer Genome Sequencing Data. Kumar RD, Chang LW, Ellis MJ, Bose R. PLoS One. 2013 Jun 27;8(6):e67980. PMID: 23826350.',
              source_db_version: '27-Jun-2013',
              source_db_name:    source_db_name,
              full_name:         'dGENE - The Druggable Gene List',
              license_link:      'https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0067980#pone.0067980.s002',
              license:           'Creative Commons Attribution License (Version not specified)'
          }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end

    def create_gene_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        if row['tax_id'] == '9606'
          gene_claim = create_gene_claim(row['Symbol'], 'Gene Symbol')
          create_gene_claim_alias(gene_claim, row['GeneID'], 'Gene ID')
          row['Synonyms'].split('|').each do |indv_synonym|
            create_gene_claim_alias(gene_claim, indv_synonym, 'dGene Synonym')
          end
          create_gene_claim_category(gene_claim, categories[row['class']])
          if row['class'] == 'PI3K' || row['class'] == 'ST_KINASE' || row['class'] == 'Y_KINASE'
            create_gene_claim_category(gene_claim, 'KINASE')
          end
        end
      end
    end

    def categories
      @categories ||= {
          'GPCR' => 'G PROTEIN COUPLED RECEPTOR',
          'NHR' => 'NUCLEAR HORMONE RECEPTOR',
          'PI3K' => 'PHOSPHATIDYLINOSITOL 3 KINASE',
          'PROTEASE' => 'PROTEASE',
          'PROT_INHIB' => 'PROTEASE INHIBITOR',
          'PTEN' => 'PTEN FAMILY',
          'PTP' => 'PROTEIN PHOSPHATASE',
          'PTP_MTMR' => 'MYOTUBULARIN RELATED PROTEIN PHOSPHATASE',
          'ST_KINASE' => 'SERINE THREONINE KINASE',
          'Y_KINASE' => 'TYROSINE KINASE'
      }
    end
  end
end;end;end
