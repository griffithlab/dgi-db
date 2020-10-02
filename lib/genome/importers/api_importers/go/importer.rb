module Genome; module Importers; module ApiImporters; module Go;
  class Importer < Genome::Importers::Base
    attr_reader :new_version
    def initialize(source_db_version = Date.today.strftime("%d-%B-%Y"))
      @new_version = source_db_version
      @source_db_name = 'GO'
    end

    def create_claims
      create_gene_claims
    end

    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url:           'http://amigo.geneontology.org/amigo/gene_product/UniProtKB:',
          site_url:           'http://www.geneontology.org/',
          citation:           'Gene ontology: tool for the unification of biology. The unification of biology. The Gene Ontology Consortium. Ashburner M, Ball CA, ..., Rubin GM, Sherlock G. Nat Genet. 2000 May;25(1):25-9. PMID: 10802651.',
          source_db_version:  @new_version,
          source_db_name:     source_db_name,
          full_name:          'The Gene Ontology',
          license:            'Creative Commons Attribution 4.0 Unported License',
          license_link:        'http://geneontology.org/docs/go-citation-policy/',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'potentially_druggable')
      @source.save
    end

    def create_gene_claims
      api_client = ApiClient.new
      categories.each do |category, go_id|
        start = 0
        rows = 500
        genes = api_client.genes_for_go_id(go_id, start, rows)
        while genes.count > 0 do
          genes.each do |gene|
            if gene['taxon_label'] == 'Homo sapiens'
              create_gene_claim_for_entry(gene, category)
            end
          end
          start += rows
          genes = api_client.genes_for_go_id(go_id, start, rows)
        end
      end
    end

    def create_gene_claim_for_entry(gene, category)
      gene_claim = create_gene_claim(gene['bioentity_label'], 'Gene Symbol')
      unless gene['synonym'].nil?
        gene['synonym'].each do |synonym|
          if synonym.include? 'UniProtKB:'
            create_gene_claim_alias(gene_claim, synonym.gsub('UniProtKB:', ''), 'UniProtKB ID')
          else
            create_gene_claim_alias(gene_claim, synonym, 'GO Gene Synonym')
          end
        end
      end
      create_gene_claim_category(gene_claim, category)
    end

    def categories
      {
        "KINASE" => "0016301",
        "TYROSINE KINASE" => "0004713",
        "SERINE THREONINE KINASE" => "0004674",
        "PROTEIN PHOSPHATASE" => "0004721",
        "G PROTEIN COUPLED RECEPTOR" => "0004930",
        "NEUTRAL ZINC METALLOPEPTIDASE" => "0008237",
        "ABC TRANSPORTER" => "0042626",
        "RNA DIRECTED DNA POLYMERASE" => "0003964",
        "TRANSPORTER" => "0005215",
        "ION CHANNEL" => "0005216",
        "NUCLEAR HORMONE RECEPTOR" => "0004879",
        "LIPID KINASE" => "0001727",
        "PHOSPHOLIPASE" => "0004620",
        "PROTEASE INHIBITOR" => "0030414",
        "DNA REPAIR" => "0006281",
        "CELL SURFACE" => "0009986",
        "EXTERNAL SIDE OF PLASMA MEMBRANE" => "0009897",
        "GROWTH FACTOR" => "0008083",
        "HORMONE ACTIVITY" => "0005179",
        "TUMOR SUPPRESSOR" => "0051726",
        "TRANSCRIPTION FACTOR BINDING" => "0008134",
        "TRANSCRIPTION FACTOR COMPLEX" => "0005667",
        "HISTONE MODIFICATION" => "0016570",
        "DRUG METABOLISM" => "0017144",
        "DRUG RESISTANCE" => "0042493",
        "PROTEASE" => "0008233",
      }
    end
  end
end; end; end; end
