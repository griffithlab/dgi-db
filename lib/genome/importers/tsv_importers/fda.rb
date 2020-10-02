module Genome; module Importers; module TsvImporters;
  class Fda < Genome::Importers::Base
    attr_reader :file_path
    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'FDA'
    end

    def get_version
      source_db_version = Date.today.strftime('%d-%B-%Y')
      @new_version = source_db_version
    end

    def creaet_claims
      create_interaction_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
          {
              base_url: 'https://www.fda.gov/drugs/science-and-research-drugs/table-pharmacogenomic-biomarkers-drug-labeling',
              site_url: 'https://www.fda.gov/drugs/science-and-research-drugs/table-pharmacogenomic-biomarkers-drug-labeling',
              citation: 'https://www.fda.gov/drugs/science-and-research-drugs/table-pharmacogenomic-biomarkers-drug-labeling',
              source_db_version:  get_version,
              source_db_name: source_db_name,
              full_name: 'FDA Pharmacogenomic Biomarkers',
              license: 'Public Domain',
              license_link: 'https://www.fda.gov/about-fda/about-website/website-policies#linking',
          }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_drug_claims(row, gene_claim, fusion_protein)
      if row['Drug'].include?(',')
        combination_therapy = row['Drug']
        row['Drug'].split(',').each do |drug|
          drug_claim = create_drug_claim(drug, drug, 'FDA Drug Name')
          interaction_claim = create_interaction_claim(gene_claim, drug_claim)
          create_interaction_claim_attribute(interaction_claim, 'Combination therapy', combination_therapy)
          if not fusion_protein.nil?
            create_interaction_claim_attribute(interaction_claim, 'Fusion protein', fusion_protein)
          end
          create_interaction_claim_link(interaction_claim, 'Table of Pharmacogenomic Biomarkers in Drug Labeling', 'https://www.fda.gov/drugs/science-and-research-drugs/table-pharmacogenomic-biomarkers-drug-labeling')
        end
      else
        drug_claim = create_drug_claim(row['Drug'], row['Drug'], 'FDA Drug Name')
        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        if not fusion_protein.nil?
          create_interaction_claim_attribute(interaction_claim, 'Fusion protein', fusion_protein)
        end
        create_interaction_claim_link(interaction_claim, 'Table of Pharmacogenomic Biomarkers in Drug Labeling', 'https://www.fda.gov/drugs/science-and-research-drugs/table-pharmacogenomic-biomarkers-drug-labeling')
      end
    end

    def create_interaction_claims
      CSV.foreach(file_path, encoding:'iso-8859-1:utf-8', :headers => true, :col_sep => "\t") do |row|
        if row['Biomarker'].include?(':')
          fusion_protein = row['Biomarker']
          row['Biomarker'].split(':').each do |indv_gene|
            gene_claim = create_gene_claim(indv_gene, 'FDA Gene Name')
            create_drug_claims(row, gene_claim, fusion_protein)
          end
        else
          row['Biomarker'].split(',').each do |indv_gene|
            gene_claim = create_gene_claim(indv_gene, 'FDA Gene Name')
            create_drug_claims(row, gene_claim, nil)
          end
        end
      end
    end
  end
end; end; end
