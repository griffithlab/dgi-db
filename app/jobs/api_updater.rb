class ApiUpdater < Updater
  def import
    @importer = create_importer
    importer.import
  end
end
