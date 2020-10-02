require 'net/http'
require 'openssl'
require 'zip'

OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE

class UpdatePharmgkb < TsvUpdater
  def tempfile_name
    ['pharmgkb_interactions', '.tsv']
  end

  def create_importer
    Genome::Importers::TsvImporters::Pharmgkb.new(tempfile)
  end

  def download_file
    uri = URI('https://s3.pgkb.org/data/relationships.zip')
    response = Net::HTTP.start(uri.host, uri.port,
                    :use_ssl => uri.scheme == 'https') do |http|
      request = Net::HTTP::Get.new uri
      http.request(request)
    end
    Zip::InputStream.open(StringIO.new(response.body)) do |io|
      while entry = io.get_next_entry
        if entry.name == 'relationships.tsv'
          tempfile.write(io.read.encode("ASCII-8BIT").force_encoding("utf-8"))
        end
      end
    end
  end

  def should_group_genes?
    true
  end

  def should_group_drugs?
    true
  end

  def should_cleanup_gene_claims?
    false
  end
end
