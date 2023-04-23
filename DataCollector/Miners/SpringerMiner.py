import bs4
import requests

from DataCollector.Miners.Miner import Miner


class SpringerMiner(Miner):
    def __init__(self, term, start_year, end_year, path):
        super().__init__(term, start_year, end_year, path)
        self.springer_base_url = "https://link.springer.com"
        self.springer_web_url = self.springer_base_url + "/search/page/{page}?query={term}&date-facet-mode=between&facet-start-year={year}&previous-start-year={year}&facet-end-year={year}&previous-end-year={year}"

    def _get_editorial(self):
        return "SPRINGER"

    def _get_request_header(self):
        headers = {
            'content-type': "application/json",
            'accept': "application/json",
            'accept-encoding': "gzip, deflate, br",
            'user-agent': "Magic Browser"
        }
        return headers

    def _get_token(self):
        r = requests.get(self.iee_web_url.format(term=self.term, year=self.start_year),
                         headers=self._get_request_header())
        return r.cookies['ERIGHTS']

    def _find_springer_pages(self, parse):
        year_total_pages = 1
        check_content_exist = False if parse.find_all("div", {"id": "no-results-message"}) else True
        if check_content_exist:
            year_total_pages = 1
            pages = parse.find_all("span", {"class": "number-of-pages"})
            if pages:
                return int(pages[0].contents[0])
            return 1  # At least 1
        else:
            return 0  # No content

    def _get_springer_citations(self, href):
        url = self.springer_base_url + href
        r = requests.get(url, headers=self._get_request_header())
        parse = bs4.BeautifulSoup(r.text, features="html.parser")
        raw_citations = parse.find_all("p", {"class": "c-article-metrics-bar__count"})
        if len(raw_citations) > 1:
            raw_citations = raw_citations[1]  # Need pick second one because first is access
            return int(raw_citations.contents[0])
        return 0

    def _get_limit(self, year):
        url = self.springer_web_url.format(page=0, term=self.term, year=year)
        r = requests.get(url, headers=self._get_request_header())
        parse = bs4.BeautifulSoup(r.text, features="html.parser")
        return self._find_springer_pages(parse)

    def _get_current_increase(self):
        return 1

    def _get_list_current_list_of_papers(self, year, current):
        url = self.springer_web_url.format(page=current, term=self.term, year=year)
        r = requests.get(url, headers=self._get_request_header())
        parse = bs4.BeautifulSoup(r.text, features="html.parser")
        result = parse.find("ol", {"id": "results-list"})
        if result:
            return result.find_all("li", recursive=False)
        return []

    def _get_content_title(self, paper):
        raw_title = paper.find("a", {"class": "title"})
        title = raw_title.find(text=True, recursive=False)
        return title if title is None else title.replace('"', "'")

    def _get_content_citations(self, paper):
        raw_title = paper.find("a", {"class": "title"})
        href = raw_title['href']
        citations = self._get_springer_citations(href)
        return citations
    def _get_content_authors(self, paper):
        raw_authors = paper.find("span", {"class": "authors"})
        authors = ""
        if raw_authors:  # It is possible n authors defined
            authors = "".join(author.contents[0] + ", " for author in raw_authors.find_all("a"))[:-2]
        authors = authors if authors is None else authors.replace('"', "'")
        return authors
