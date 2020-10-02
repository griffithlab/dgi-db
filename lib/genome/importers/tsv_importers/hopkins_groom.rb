module Genome; module Importers; module TsvImporters
  class HopkinsGroom < Genome::Importers::Base
    attr_reader :file_path
    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'HopkinsGroom'
    end

    def get_version
      source_db_version = Date.today.strftime("%d-%B-%Y")
      @new_version = source_db_version
    end

    def create_claims
      create_gene_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url:           'http://www.uniprot.org/uniprot/',
          site_url:           'http://www.ncbi.nlm.nih.gov/pubmed/12209152/',
          citation:           'The druggable genome. Hopkins AL, Groom CR. Nat Rev Drug Discov. 2002 Sep;1(9):727-30. PMID: 12209152',
          source_db_version:  '11-Sep-2012',
          source_db_name:     source_db_name,
          full_name:          'The druggable genome (Hopkins & Groom, 2002)',
          license:            'Supplementary data from Nature Publishing Group copyright publication',
          license_link:       'https://www.nature.com/articles/nrd892',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end

    def create_gene_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        gene_claim = create_gene_claim(row['Uniprot_Acc'], 'HopkinsGroom Gene Name')
        create_gene_claim_alias(gene_claim, row['Uniprot_Acc'].upcase, 'Uniprot Accession')
        create_gene_claim_alias(gene_claim, row['Uniprot_Id'].upcase, 'Uniprot Id')
        create_gene_claim_alias(gene_claim, row['Uniprot_Protein_Name'].upcase, 'Uniprot Protein Name')
        create_gene_claim_alias(gene_claim, row['Uniprot_Protein_Name'].upcase, 'Uniprot Protein Name')
        create_gene_claim_alias(gene_claim, row['Uniprot_Gene_Name'].upcase, 'Uniprot Gene Name') unless row['Uniprot_Gene_Name'] == 'N/A'
        create_gene_claim_alias(gene_claim, row['Entrez_Id'].upcase, 'Entrez Gene Id') unless row['Entrez_Id'] == 'N/A'
        row['Ensembl_Id'].split('; ').each do |ensembl_id|
          create_gene_claim_alias(gene_claim, ensembl_id.upcase, 'Ensembl Gene Id') unless ensembl_id == 'N/A'
        end
        create_gene_claim_category(gene_claim, 'DRUGGABLE GENOME')
        unless row['DGIDB_Human_Readable'] == 'N/A'
          create_gene_claim_category(gene_claim, row['DGIDB_Human_Readable'].gsub('/', ' ').gsub('.', '_').upcase)
        end
        create_gene_claim_attribute(gene_claim, 'Interpro Acc', row['Interpro_Acc'])
        create_gene_claim_attribute(gene_claim, 'Uniprot Evidence', row['Uniprot_Evidence'])
        create_gene_claim_attribute(gene_claim, 'Uniprot Status', row['Uniprot_Status'])
        create_gene_claim_attribute(gene_claim, 'Interpro Short Name', row['Interpro_Short_Name'])
        create_gene_claim_attribute(gene_claim, 'Interpro Type', row['Interpro_Type'])
      end
    end
  end
end; end; end
