module Genome; module Importers; module TsvImporters
  class Cgi < Genome::Importers::Base
    attr_reader :file_path
    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'CGI'
    end

    def get_version
      source_db_version = Date.today.strftime("%d-%B-%Y")
      @new_version = source_db_version
    end

    def create_claims
      create_interaction_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
          {
              base_url: 'https://www.cancergenomeinterpreter.org/biomarkers',
              site_url: 'https://www.cancergenomeinterpreter.org/',
              citation: 'https://www.cancergenomeinterpreter.org/',
              source_db_version:  get_version,
              source_db_name: source_db_name,
              full_name: 'Cancer Genome Interpreter',
              license: 'Creative Commons Attribution-NonCommercial 4.0 (BY-NC)',
              license_link: 'https://www.cancergenomeinterpreter.org/faq#q11c',
          }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def create_interaction_claims
      CSV.foreach(file_path, :headers => true, :col_sep => "\t") do |row|
        next if row['Drug'].nil? || row['Drug'] == '[]'
        if row['Drug'].include?(',') || row['Drug'].include?(';')
          combination_drug_name = row['Drug']
          combination_drug_name.scan(/[a-zA-Z0-9]+/).each do |individual_drug_name|
            drug_claim = create_drug_claim(individual_drug_name, individual_drug_name, 'CGI Drug Name')
            if row['Gene'].include?(';')
              row['Gene'].split(';').each do |indv_gene|
                gene_claim = create_gene_claim(indv_gene, 'CGI Gene Name')
                interaction_claim = create_interaction_claim(gene_claim, drug_claim)
                create_interaction_claim_attribute(interaction_claim, 'combination therapy', combination_drug_name)
                create_interaction_claim_attribute(interaction_claim, 'Drug family', row['Drug family'])
                create_interaction_claim_attribute(interaction_claim, 'Alteration', row['Alteration'])
                if row['Source'].include?('PMID')
                  add_interaction_claim_publications(interaction_claim, row['Source'])
                end
                create_interaction_claim_link(interaction_claim, 'Cancer Biomarkers database', 'https://www.cancergenomeinterpreter.org/biomarkers')
              end
            else
              gene_claim = create_gene_claim(row['Gene'], 'CGI Gene Name')
              interaction_claim = create_interaction_claim(gene_claim, drug_claim)
              create_interaction_claim_attribute(interaction_claim, 'combination therapy', combination_drug_name)
              create_interaction_claim_attribute(interaction_claim, 'Drug family', row['Drug family'])
              create_interaction_claim_attribute(interaction_claim, 'Alteration', row['Alteration'])
              if row['Source'].include?('PMID')
                add_interaction_claim_publications(interaction_claim, row['Source'])
              end
              create_interaction_claim_link(interaction_claim, 'Cancer Biomarkers database', 'https://www.cancergenomeinterpreter.org/biomarkers')
            end
          end
        if row['Drug'].include?(';')
          combination_drug_name = row['Drug']
          combination_drug_name.split(';').each do |individual_drug_name|
            drug_claim = create_drug_claim(individual_drug_name, individual_drug_name, 'CGI Drug Name')
            if row['Gene'].include?(';')
              row['Gene'].split(';').each do |indv_gene|
                gene_claim = create_gene_claim(indv_gene, 'CGI Gene Name')
                interaction_claim = create_interaction_claim(gene_claim, drug_claim)
                create_interaction_claim_attribute(interaction_claim, 'combination therapy', combination_drug_name)
                create_interaction_claim_attribute(interaction_claim, 'Drug family', row['Drug family'])
                create_interaction_claim_attribute(interaction_claim, 'Alteration', row['Alteration'])
                if row['Source'].include?('PMID')
                  add_interaction_claim_publications(interaction_claim, row['Source'])
                end
                create_interaction_claim_link(interaction_claim, 'Cancer Biomarkers database', 'https://www.cancergenomeinterpreter.org/biomarkers')
              end
            else
              gene_claim = create_gene_claim(row['Gene'], 'CGI Gene Name')
              interaction_claim = create_interaction_claim(gene_claim, drug_claim)
              create_interaction_claim_attribute(interaction_claim, 'combination therapy', combination_drug_name)
              create_interaction_claim_attribute(interaction_claim, 'Drug family', row['Drug family'])
              create_interaction_claim_attribute(interaction_claim, 'Alteration', row['Alteration'])
              if row['Source'].include?('PMID')
                add_interaction_claim_publications(interaction_claim, row['Source'])
              end
              create_interaction_claim_link(interaction_claim, 'Cancer Biomarkers database', 'https://www.cancergenomeinterpreter.org/biomarkers')
            end
          end
        end
        else
          drug_claim = create_drug_claim(row['Drug'], row['Drug'], 'CGI Drug Name')
          if row['Gene'].include?(';')
            row['Gene'].split(';').each do |indv_gene|
              gene_claim = create_gene_claim(indv_gene, 'CGI Gene Name')
              interaction_claim = create_interaction_claim(gene_claim, drug_claim)
              create_interaction_claim_attribute(interaction_claim, 'Drug family', row['Drug family'])
              create_interaction_claim_attribute(interaction_claim, 'Alteration', row['Alteration'])
              if row['Source'].include?('PMID')
                add_interaction_claim_publications(interaction_claim, row['Source'])
              end
              create_interaction_claim_link(interaction_claim, 'Cancer Biomarkers database', 'https://www.cancergenomeinterpreter.org/biomarkers')
            end
          else
            gene_claim = create_gene_claim(row['Gene'], 'CGI Gene Name')
            interaction_claim = create_interaction_claim(gene_claim, drug_claim)
            create_interaction_claim_attribute(interaction_claim, 'Drug family', row['Drug family'])
            create_interaction_claim_attribute(interaction_claim, 'Alteration', row['Alteration'])
            if row['Source'].include?('PMID')
              add_interaction_claim_publications(interaction_claim, row['Source'])
            end
            create_interaction_claim_link(interaction_claim, 'Cancer Biomarkers database', 'https://www.cancergenomeinterpreter.org/biomarkers')
          end
        end
      end
      backfill_publication_information()
    end



    def add_interaction_claim_publications(interaction_claim, source_string)
      if source_string.include?(';')
        source_string.split(';').each do |value|
          value.split(/[^\d]/).each do |pmid|
            unless pmid.nil? || pmid == ''
              create_interaction_claim_publication(interaction_claim, pmid)
            end
          end
        end
      else
        source_string.split(':').last do |pmid|
          create_interaction_claim_publication(interaction_claim, pmid)
        end
      end
    end
  end
end; end; end
