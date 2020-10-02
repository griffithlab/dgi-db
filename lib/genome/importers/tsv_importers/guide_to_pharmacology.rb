include ActionView::Helpers::SanitizeHelper

module Genome; module Importers; module TsvImporters;
  class GuideToPharmacology < Genome::Importers::Base
    attr_reader :interaction_file_path, :gene_file_path, :target_to_entrez
    def initialize(interaction_file_path, gene_file_path)
      @interaction_file_path = interaction_file_path
      @gene_file_path = gene_file_path
      @target_to_entrez = {}
      @source_db_name = 'GuideToPharmacology'
    end

    def create_claims
      import_claims
    end

    private
    def import_claims
      CSV.foreach(gene_file_path, :headers => true) do |line|
        gene_name = line['Human Entrez Gene']
        next if blank?(gene_name)

        gene_claim = create_gene_claim(gene_name, "Entrez Gene ID")
        target_to_entrez[line['Target id']] = gene_name

        unless blank?(line['HGNC id'])
          create_gene_claim_alias(gene_claim, line['HGNC id'], 'HUGO Gene ID')
        end
        unless blank?(line['HGNC symbol'])
          create_gene_claim_alias(gene_claim, line['HGNC id'], 'HUGO Gene Symbol')
        end
        unless blank?(line['HGNC name'])
          create_gene_claim_alias(gene_claim, line['HGNC name'], 'HUGO Gene Name')
        end
        create_gene_claim_alias(gene_claim, line['Target id'], 'GuideToPharmacology ID')
        create_gene_claim_alias(gene_claim, line['Target name'], 'GuideToPharmacology Name')
        unless blank?(line['Human nucleotide RefSeq'])
          create_gene_claim_alias(gene_claim, line['Human nucleotide RefSeq'], 'RefSeq Nucleotide Accession')
        end
        unless blank?(line['Human protein RefSeq'])
          create_gene_claim_alias(gene_claim, line['Human protein RefSeq'], 'RefSeq Protein Accession')
        end
        unless blank?(line['Human SwissProt'])
          create_gene_claim_alias(gene_claim, line['Human SwissProt'], 'SwissProt Accession')
        end

        create_gene_claim_attribute(gene_claim, 'GuideToPharmacology Gene Category Name', line['Family name'])
        create_gene_claim_attribute(gene_claim, 'GuideToPharmacology Gene Category ID', line['Family id'])

        category_lookup = {
          #"catalytic_receptor" => '',
          "enzyme" => 'ENZYME',
          "gpcr" => 'G PROTEIN COUPLED RECEPTOR',
          "lgic" => 'ION CHANNEL',
          "nhr" => 'NUCLEAR HORMONE RECEPTOR',
          "other_ic" => 'ION CHANNEL',
          #"other_protein" => '',
          "transporter" => 'TRANSPORTER',
          "vgic" => 'ION CHANNEL',
        }
        if category_lookup.has_key? line['Type']
          create_gene_claim_category(gene_claim, category_lookup[line['Type']])
        end
      end
      CSV.foreach(interaction_file_path, :headers => true) do |line|
        next unless valid_line?(line)
        gene_claim = create_gene_claim(target_to_entrez[line['target_id']], 'Entrez Gene ID')
        create_gene_claim_aliases(gene_claim, line)

        drug_claim = create_drug_claim(line['ligand_pubchem_sid'], strip_tags(line['ligand']).upcase, 'PubChem Drug SID')
        create_drug_claim_aliases(drug_claim, line)
        create_drug_claim_attribute(drug_claim, 'Name of the Ligand Species (if a Peptide)', line['ligand_species']) unless blank?(line['ligand_species'])

        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        type = line['type'].downcase
        create_interaction_claim_type(interaction_claim, type) unless type == 'none'
        unless blank?(line['pubmed_ids'])
          line['pubmed_ids'].split('|').each do |pmid|
            create_interaction_claim_publication(interaction_claim, pmid)
          end
        end
        create_interaction_claim_attributes(interaction_claim, line)
        create_interaction_claim_link(interaction_claim, "Ligand Biological Activity", "https://www.guidetopharmacology.org/GRAC/LigandDisplayForward?ligandId=#{line['ligand_id']}&tab=biology")
      end
      backfill_publication_information()
    end

    def valid_line?(line)
      line['target_species'] == 'Human' && blank?(line['target_ligand']) && !blank?(line['ligand_pubchem_sid']) && !blank?(line['target_ensembl_gene_id']) && !blank?(target_to_entrez[line['target_id']])
    end

    def create_gene_claim_aliases (gene_claim, line)
      create_gene_claim_alias(gene_claim, line['target'], 'GuideToPharmacology Name') unless blank?(line['target'])
      unless blank?(line['target_ensembl_gene_id'])
        line['target_ensembl_gene_id'].split('|').each do |ensembl_id|
          create_gene_claim_alias(gene_claim, ensembl_id, 'Ensembl ID')
        end
      end
      unless blank?(line['target_gene_symbol'])
        line['target_gene_symbol'].split('|').each do |gene_symbol|
          create_gene_claim_alias(gene_claim, gene_symbol, 'Gene Symbol')
        end
      end
      unless blank?(line['target_uniprot'])
       line['target_uniprot'].split('|').each do |uniprot_id|
          create_gene_claim_alias(gene_claim, uniprot_id, 'UniProtKB ID')
        end
      end
    end

    def create_drug_claim_aliases(drug_claim, line)
      unless blank?(line['ligand_gene_symbol'])
        line['ligand_gene_symbol'].split('|').each do |gene_symbol|
          create_drug_claim_alias(drug_claim, gene_symbol, 'Gene Symbol (for Endogenous Peptides)')
        end
      end
      create_drug_claim_alias(drug_claim, strip_tags(line['ligand']).upcase, 'GuideToPharmacology Ligand Name')
    end

    def blank?(value)
      value.blank? || value == "''" || value == '""'
    end

    def create_interaction_claim_attributes(interaction_claim, line)
      attributes = {
        'Interaction Context': line['ligand_context'],
        'Specific Binding Site for Interaction': line['receptor_site'],
        'Details of the Assay for Interaction': line['assay_description'],
        'Specific Action of the Ligand': line['action'],
        'Details of Interaction': line['action_comment'],
        'Endogenous Drug?': line['endogenous'],
        'Direct Interaction?': line['primary_target'],
      }
      boolean_parser = {
        't' => 'True',
        'f' => 'False',
      }
      attributes.each do |name, value|
        next if blank?(value)
        parsed_value = boolean_parser[value] || value
        create_interaction_claim_attribute(interaction_claim, name, parsed_value)
      end
    end

    def create_new_source
      @source = DataModel::Source.where(
          base_url: 'http://www.guidetopharmacology.org/DATA/',
          site_url: 'http://www.guidetopharmacology.org/',
          citation: 'Pawson, Adam J., et al. "The IUPHAR/BPS Guide to PHARMACOLOGY: an expert-driven knowledgebase 
of drug targets and their ligands." Nucleic acids research 42.D1 (2014): D1098-D1106. PMID: 24234439.',
          source_db_name: source_db_name,
          full_name: 'Guide to Pharmacology',
          license: 'Creative Commons Attribution-ShareAlike 4.0 International License',
          license_link: 'https://www.guidetopharmacology.org/about.jsp',
      ).first_or_initialize
      source.source_db_version = Date.today.strftime("%d-%B-%Y")
      source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      source.save
    end
  end
end; end; end;
