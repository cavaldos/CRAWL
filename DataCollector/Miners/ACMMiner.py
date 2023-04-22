import bs4
import requests

from DataCollector.Miners.Miner import Miner
from DataCollector.InvalidData import InvalidData

class ACMMiner(Miner):
    def __init__(self, term, start_year, end_year, path):
        super().__init__(term, start_year, end_year, path)
        self.reg_for_page = 50
        self.acm_base_url = "https://dl.acm.org"
        self.acm_web_url = self.acm_base_url + "/action/doSearch?fillQuickSearch=false&target=advanced&expand=dl&field1=AllField&text1={term}&AfterYear={year}&BeforeYear={year}&startPage={page}&pageSize=" + str(self.reg_for_page)
    def _get_editorial(self):
        return "ACM"

    def _get_request_header(self):
        headers = {
            'content-type': "application/json",
            'accept': "application/json",
            'accept-encoding': "gzip, deflate, br",
            'user-agent': "Magic Browser"
        }
        return headers


    def _find_acm_pages(self, parse):
        if parse:
            parse = parse.find("span", {"class": "result__count"})
            if parse:
                records = parse.find(text=True, recursive=False).split()[0]
            else:
                return 0
            records = int(records.replace(",",""))
            return int(records/self.reg_for_page) + 1 if records != 0 else 0
        return 0


    def _get_limit(self, year):
        url = self.acm_web_url.format(page=0, term=self.term, year=year)
        r = requests.get(url, headers=self._get_request_header())
        parse = bs4.BeautifulSoup(r.text, features="html.parser")
        return self._find_acm_pages(parse)

    def _get_current_increase(self):
        return 1

    def _get_list_current_list_of_papers(self, year, current):
        url = self.acm_web_url.format(page=current, term=self.term, year=year)
        r = requests.get(url, headers=self._get_request_header())
        parse = bs4.BeautifulSoup(r.text, features="html.parser")
        result = parse.find("ul", {"class": "items-results"})
        if result:
            return result.find_all("li", recursive=False)
        return []

    def _get_content_title(self, paper):
        raw_title = paper.find("span", {"class": "hlFld-Title"})
        if not raw_title:
            raise InvalidData("It's a conference")
        raw_title = raw_title.find("a")
        title = raw_title.findAll(text=True, recursive=True)
        title = "".join(t for t in title)
        return title if title is None else title.replace('"', "'")

    def _get_content_citations(self, paper):
        raw_citations = paper.find("span", {"class": "citation"})
        citations = raw_citations.find("span").find(text=True, recursive=False)
        citations = citations.replace(",","")
        citations = int(citations) if citations else 0
        return citations


    def _get_content_authors(self, paper):
        raw_authors = paper.find("ul", {"aria-label": "authors"})
        authors = ""
        if raw_authors:  # It is possible n authors defined
            for li in raw_authors.find_all("li"):
                authors += li.find(text=True, recursive=True) + ", "
            authors = authors[:-2]
        authors = authors if authors is None else authors.replace('"', "'")
        return authors
