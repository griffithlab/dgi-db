require 'tempfile'
require 'open-uri'

class TsvUpdater < Updater
  attr_reader :tempfile

  def import
    begin
      create_tempfile
      download_file
      @importer = create_importer
      importer.import
    ensure
      remove_download
    end
  end

  def create_tempfile
    @tempfile = Tempfile.new(tempfile_name, temp_path)
  end

  def temp_path
    File.join(Rails.root, 'tmp')
  end

  def tempfile_name
    raise StandardError.new('Must implement #tempfile_name in subclass')
  end

  def download_file
    download_stream = open(latest_url, open_timeout: 300)
    IO.copy_stream(download_stream, tempfile)
  end

  def latest_url
    raise StandardError.new('Must implement #latst_url in subclass')
  end

  def remove_download
    tempfile.close
    tempfile.unlink
  end
end
