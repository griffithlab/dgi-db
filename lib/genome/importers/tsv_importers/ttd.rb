module Genome; module Importers; module TsvImporters
  class TTD < Genome::Importers::Base
    attr_reader :file_path
    def initialize(file_path)
      @file_path = file_path
      @source_db_name = 'TTD'
    end

    def create_claims
      import_claims
    end

    private
    def create_new_source
      @source ||= DataModel::Source.create(
        {
          base_url:          'http://db.idrblab.net/ttd/',
          site_url:          'http://bidd.nus.edu.sg/group/cjttd/',
          citation:          "Update of TTD: Therapeutic Target Database. Zhu F, Han BC, ..., Zheng CJ, Chen YZ. Nucleic Acids Res. 38(suppl 1):D787-91, 2010. PMID: 19933260.",
          source_db_version:  '2020.06.01',
          source_db_name:    source_db_name,
          full_name:         'Therapeutic Target Database',
          license: 'Unclear. Website states "All Rights Reserved" but resource structure and description in 2002 publication indicate "open-access".',
          license_link: 'https://academic.oup.com/nar/article/30/1/412/1331814',
        }
      )
      @source.source_types << DataModel::SourceType.find_by(type: 'interaction')
      @source.save
    end

    def import_claims
      CSV.foreach(file_path, :headers => true, :col_sep => ",") do |row|
        next if row['Highest_status'] == 'Terminated' || row['Highest_status'] == 'Withdrawn from market' || row['Highest_status'].match(/Discontinued/) || row['Highest_status'] == 'Investigative'

        gene_name, gene_abbreviation = row['Target_Name'].split(' (', 2)
        gene_abbreviation.sub!(')', '')
        gene_claim = create_gene_claim(gene_name, 'TTD Target Name')
        create_gene_claim_alias(gene_claim, gene_abbreviation, 'TTD Gene Abbreviation')
        create_gene_claim_alias(gene_claim, row['TargetID'], 'TTD Target ID')

        drug_claim = create_drug_claim(row['Drug_Name'], row['Drug_Name'], 'TTD Drug Name')
        create_drug_claim_alias(drug_claim, row['DrugID'], 'TTD Drug ID')

        interaction_claim = create_interaction_claim(gene_claim, drug_claim)
        if !row['MOA'].nil? and !row['MOA'] == '.'
          create_interaction_claim_type(interaction_claim, Genome::Normalizers::InteractionClaimType.name_normalzier(row['MOA']))
        end

        #this is not a typo but the actual column header from the source TSV
        if !row['Referecnce'].nil?
          row['Referecnce'].split('; ').each do |ref|
            if ref.include? 'pubmed'
              url, sep, pmid = ref.rpartition('/')
              if pmid == ''
                pmid = url.rpartition('/').last
              end
              if !pmid == '217546303'
                create_interaction_claim_publication(interaction_claim, pmid)
              end
            end
            if ref.include? 'pmc'
              url, sep, pmcid = ref.rpartition('/')
              if pmcid == ''
                pmcid = url.rpartition('/').last
              end
              create_interaction_claim_publication_by_pmcid(interaction_claim, pmcid)
            end
          end
        end

        create_interaction_claim_link(interaction_claim, 'TTD Target Information', "http://idrblab.net/ttd/data/target/details/#{row['TargetID']}")
      end
      backfill_publication_information()
    end
  end
end; end; end
