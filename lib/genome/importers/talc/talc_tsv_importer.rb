module Genome
  module Importers
    module TALC
      def source_info
        {
          base_url:          'http://www.ncbi.nlm.nih.gov/gene?term=',
          site_url:          'http://www.ncbi.nlm.nih.gov/pubmed/22005529/',
          citation:          "Molecular targeted agents and biologic therapies for lung cancer. Somaiah N, Simon GR. J Thorac Oncol. 2011 Nov;6(11 Suppl 4):S1758-85. PMID: 22005529",
          source_db_version: '16-Jul-2012',
          source_type_id:    DataModel::SourceType.INTERACTION,
          source_db_name:    'TALC',
          full_name:         'Targeted Agents in Lung Cancer (Santa Monica Supplement, 2011)'
        }
      end

      def self.run(tsv_path)
        na_filter = ->(x) { x.upcase == 'N/A' }
        TSVImporter.import tsv_path, TALCRow, source_info do
          interaction known_action_type: 'unknown' do
            attributes :interaction_type, name: 'Interaction Type'

            gene :entrez_id, nomenclature: 'Entrez Gene Id' do
              name :target_id, nomenclature: 'Entrez Gene Id'
              name :gene_target, nomenclature: 'Gene Symbol'
            end

            drug :drug_name, nomenclature: 'TALC' do
              name :drug_name, nomenclature: 'Primary Drug Name'
              names :drug_synonym, nomenclature: 'Drug Synonym', unless: na_filter
              name :drug_generic_name, nomenclature: 'Drug Generic Name', unless: na_filter
              names :drug_trade_name, nomenclature: 'Drug Trade Name', unless: na_filter
              name :drug_cas_number, nomenclature: 'CAS Number', unless: na_filter
              name :drug_drugbank_id, nomenclature: 'Drugbank Id', unless: na_filter
              name :drug_class, nomenclature: 'Drug Class', unless: na_filter
              name :drug_type, nomenclature: 'Drug Type', unless: na_filter
            end
          end
        end
      end
    end
  end
end