import json
import re
from urllib import request
import bs4 as bs4
from DataCollector.Miners.Miner import Miner


class ElseiverMiner(Miner):
    SEARCH_OFFSET_INCREMENT = 25

    def __init__(self, term, start_year, end_year, path):
        super().__init__(term, start_year, end_year, path)
        self.cited_parser = re.compile("Cited by \([0-9]+\)")
        self.token_parser = re.compile("\"searchToken\":\".*\"},\"s")
        self.elsevier_base = "https://www.sciencedirect.com"
        self.elsevier_search_url = self.elsevier_base + "/search?qs={term}&years={year}&lastSelectedFacet=years"  # Get search token
        self.elsevier_search_url_api = self.elsevier_base + "/search/api?lastSelectedFacet=years&qs={term}&years={year}&offset={offset}&t={token}"
        self.cited_url = self.elsevier_base + "/sdfe/arp/citingArticles?pii={pii}"
        self.token = self._get_token()

    def _get_editorial(self):
        return "ELSEVIER"

    def _get_token(self):
        url = self.elsevier_search_url.format(term=self.term, year=self.start_year)
        req = request.Request(url, headers={'User-Agent': "Magic Browser"})
        con = request.urlopen(req)
        page = con.read()
        parse = bs4.BeautifulSoup(page, features="html.parser")
        raw_token = result = self.token_parser.search(str(page))
        token = result.group(0)[15:-11]
        return token

    def _get_page_json(self, year, offset):
        api_url = self.elsevier_search_url_api.format(term=self.term, year=year, token=self.token, offset=offset)
        req = request.Request(api_url, headers={'User-Agent': "Magic Browser"})
        con = request.urlopen(req)
        api_page = con.read()
        return json.loads(api_page)

    def _get_limit(self, year):
        o_json = self._get_page_json(year, 0)
        limit_offset = o_json['searchHistory']['resultsCount']
        return self.SEARCH_OFFSET_INCREMENT - 1 if limit_offset == -1 else limit_offset

    def _get_current_increase(self):
        return self.SEARCH_OFFSET_INCREMENT

    def _get_list_current_list_of_papers(self, year, current):
        o_json = self._get_page_json(year, current)
        return o_json["searchResults"]

    def _get_content_title(self, paper):
        return paper["title"].replace("<em>", "").replace("</em>", "").replace('"', "'")

    def _get_content_citations(self, paper):
        pii = paper['pii']
        citations = 0
        cited_req = request.Request(self.cited_url.format(pii=pii), headers={'User-Agent': "Magic Browser"})
        cited_con = request.urlopen(cited_req)
        cited_page = cited_con.read()
        cited_json = json.loads(cited_page)
        return cited_json['hitCount']

    def _get_content_authors(self, paper):
        authors = ""
        if "authors" in paper:
            authors = ("".join(o["name"] for o in paper["authors"]))[:-2]
        authors = authors.replace('"', "'")
        if authors == "":
            authors = "No authors available"
        return authors
