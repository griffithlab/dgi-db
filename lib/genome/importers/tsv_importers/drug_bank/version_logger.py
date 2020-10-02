__author__ = 'Alex H Wagner'

import datetime
import warnings
import csv
import os


# TODO: Currently uses a text file as a simple database. Consider using sqlite instead.
class Version:

    def __init__(self, source, version=None, append_date=False, download_path=None):
        self.version = version
        self.append = append_date
        self.source = source
        self.versions = dict()
        self.download_path = download_path
        os.makedirs(self.download_path, exist_ok=True)
        if self.version is None and not self.append:
            self.append = True
            warnings.warn("No version specified, setting logger to use date instead.")

    def load_versions(self):
        try:
            with open(self.download_path + 'version', 'r') as f:
                for line in f:
                    key, value = line.strip().split('\t')
                    self.versions[key] = value
        except FileNotFoundError:
            self.versions = dict()

    def is_current(self):
        return self.version == self.last_logged_version()

    def write_log(self):
        self.load_versions()
        if self.append:
            today = datetime.date.today().strftime("%d-%B-%Y")
            if self.version is not None:
                version = "{0}, {1}".format(self.version, today)
            else:
                version = today
        else:
            version = str(self.version)
        self.versions[self.source] = version
        version_file = os.path.join(self.download_path, 'version')
        with open(version_file, 'w') as f:
            writer = csv.writer(f, delimiter='\t')
            for source in sorted(self.versions):
                writer.writerow((source, self.versions[source]))

    def last_logged_version(self):
        self.load_versions()
        try:
            logged_version = self.versions[self.source]
        except KeyError:
            logged_version = None
        return logged_version