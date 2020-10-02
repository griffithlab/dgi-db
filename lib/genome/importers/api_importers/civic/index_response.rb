module Genome; module Importers; module ApiImporters; module Civic
  class IndexResponse
    attr_reader :data

    def initialize(body)
      @data = JSON.parse(body)
    end

    def records
      data['records']
    end

    def total_count
      data['_meta']['total_count']
    end

    def total_pages
      data['_meta']['total_pages']
    end

    def current_page_num
      data['_meta']['current_page']
    end
  end

  class EvidenceItemResponse < IndexResponse
    def evidence_items
      records
    end
  end

  class VariantResponse < IndexResponse
    def variants
      records
    end
  end
end; end; end; end
