require 'genome/importers/delimited_row'
module Genome
  module Importers
    module Entrez
      class EntrezGenePathwayRow < Genome::Importers::DelimitedRow
        attribute :taxon_id
        attribute :entrez_gene_id
        attribute :accn_vers
        attribute :name
        attribute :keyphrase
        attribute :interactant_taxon_id
        attribute :interactant_gene_id
        attribute :interactant_id_type
        attribute :interactant_accn_vers
        attribute :interactant_name
        attribute :complex_id
        attribute :complex_id_type
        attribute :complex_name
        attribute :pubmed_id_list
        attribute :last_mod
        attribute :generif_text
        attribute :interaction_id
        attribute :interaction_id_type
      end
    end
  end
end
