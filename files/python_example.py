#!/usr/bin/env python

#This example uses the 'requests' library
#To install requests:
#   sudo pip install requests
#If you don't have pip:
#   see http://www.pip-installer.org/en/latest/installing.html
#       or
#   wget https://raw.github.com/pypa/pip/master/contrib/get-pip.py
#   sudo python get-pip.py

import sys
import argparse
import json
import requests

def usage():
  print "Usage Examples:"
  print "python python_example.py --help"
  print "python python_example.py --genes='FLT3'"
  print "python python_example.py --genes='FLT3,EGFR,KRAS'"
  print "python python_example.py --genes='FLT3,EGFR' --interaction_sources='TALC,TEND'"
  print "python python_example.py --genes='FLT3,EGFR' --gene_categories='KINASE'"
  print "python python_example.py --genes='FLT3,EGFR' --interaction_types='inhibitor'"
  print "python python_example.py --genes='FLT3,EGFR' --source_trust_levels='Expert curated'"
  print "python python_example.py --genes='FLT3,EGFR' --antineoplastic_only"
  print "python python_example.py --genes='FLT3,EGFR,KRAS' --interaction_sources='TALC,TEND,MyCancerGenome' --gene_categories='KINASE' --interaction_types='inhibitor' --antineoplastic_only"
  sys.exit(0)

def parse_args():
    parser = argparse.ArgumentParser(description = "A Python example for using the DGIdb API", epilog = "For complete API documentation refer to http://dgidb.org/api")
    parser.add_argument("-g", "--genes", help="list of gene symbols(REQUIRED). Use official Entrez symbols for best results", dest="genes")
    parser.add_argument("-is", "--interaction_sources", help="Limit results to those from particular data sources. e.g. 'DrugBank', 'PharmGKB', 'TALC', 'TEND', 'TTD', 'MyCancerGenome')", dest="interaction_sources")
    parser.add_argument("-it", "--interaction_types", help="Limit results to interactions with drugs that have a particular mechanism of action. e.g. 'inhibitor', 'antibody', etc", dest="interaction_types")
    parser.add_argument("-gc", "--gene_categories", help="Limit results to genes with a particular druggable gene type. e.g. 'KINASE', 'ION CHANNEL', etc", dest="gene_categories")
    parser.add_argument("-stl", "--source_trust_levels", help="Limit results based on trust level of the interaction source. e.g. 'Expert curated' or 'Non-curated", dest = "source_trust_levels")
    parser.add_argument("-ano", "--antineoplastic_only", help="Limit results to anti-cancer drugs only", dest="antineoplastic_only", action = 'store_true')
    parser.add_argument("-u", "--usage", help="Usage examples", dest="usage", action = 'store_true')
    return parser.parse_args()

class DGIAPI:
    'API Example class for DGI API.'
    domain = 'https://dgidb.org/'
    api_path = '/api/v1/interactions.json'
    def __init__(self, args):
        self.genes = args.genes
        self.interaction_sources = args.interaction_sources
        self.interaction_types = args.interaction_types
        self.gene_categories = args.gene_categories
        self.source_trust_levels = args.source_trust_levels
        self.antineoplastic_only = args.antineoplastic_only
    def run_workflow(self):
        self.create_request()
        self.post_request()
        self.print_response()
    def create_request(self):
        self.request = "https://dgidb.org/api/v1/interactions.json?genes=FLT1&drug_types=antineoplastic&interaction_sources=TALC"
        self.payload = {}
        if(self.genes):
            self.payload['genes'] = self.genes
        if(self.interaction_sources):
            self.payload['interaction_sources'] = self.interaction_sources
        if(self.gene_categories):
            self.payload['gene_categories'] = self.gene_categories
        if(self.interaction_types):
            self.payload['interaction_types'] = self.interaction_types
        if(self.source_trust_levels):
            self.payload['source_trust_levels'] = self.source_trust_levels
        if(self.antineoplastic_only):
            self.payload['drug_types'] = 'antineoplastic'
    def post_request(self):
        self.request = DGIAPI.domain + DGIAPI.api_path
        self.response = requests.post(self.request, data = self.payload)
    def print_response(self):
        response = json.loads(self.response.content.decode('utf-8'))
        matches = response['matchedTerms']
        if(matches):
          print "gene_name\tdrug_name\tinteraction_type\tsource\tgene_categories"
        for match in matches:
            gene = match['geneName']
            categories = match['geneCategories']
            categories.sort()
            joined_categories = ",".join(categories)
            for interaction in match['interactions']:
                source = interaction['source']
                drug = interaction['drugName']
                interaction_type = interaction['interactionType']
                print gene + "\t" + drug + "\t" + interaction_type + "\t" + source + "\t" + joined_categories.lower()
        for unmatched in response['unmatchedTerms']:
            print "Unmatched search term: " + unmatched['searchTerm']
            print "Possible suggestions: " + ",".join(unmatched['suggestions'])

if __name__ == '__main__':
    args = parse_args()
    if(not args.genes or args.usage):
      usage()
    da = DGIAPI(args)
    da.run_workflow()
