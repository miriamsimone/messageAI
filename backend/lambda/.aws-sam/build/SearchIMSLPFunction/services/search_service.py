import requests
import os
from bs4 import BeautifulSoup
import re

class SearchService:
    def __init__(self):
        self.api_key = os.getenv('BRAVE_API_KEY')
        self.base_url = "https://api.search.brave.com/res/v1/web/search"
    
    def search_tabs(self, song_name: str, num_results: int = 3):
        """Search for guitar tabs of a song with fallback to mock data"""
        queries = self.generate_tab_queries(song_name)
        results = []
        
        for query in queries[:3]:
            try:
                response = self._search(query)
                if response:
                    tab_urls = self._extract_tab_urls(response)
                    for url in tab_urls:
                        tab_content = self._fetch_tab_content(url)
                        if tab_content:
                            results.append({
                                'url': url,
                                'content': tab_content,
                                'source': self._identify_source(url)
                            })
                            if len(results) >= num_results:
                                break
            except Exception as e:
                print(f"Search failed for query '{query}': {str(e)}")
                # Continue to next query or fallback
                continue
        
        # If we didn't get enough results, use mock data as fallback
        if len(results) < 2:
            print(f"Using mock data fallback for '{song_name}'")
            results = self._get_mock_tabs(song_name, num_results)
        
        return results[:num_results]
    
    def generate_tab_queries(self, song_name: str):
        """Generate search queries optimized for finding tabs"""
        return [
            f"{song_name} guitar tab",
            f"{song_name} chords lyrics",
            f"{song_name} ultimate guitar"
        ]
    
    def _search(self, query: str):
        """Search using Brave Search API"""
        try:
            headers = {
                'Accept': 'application/json',
                'X-Subscription-Token': self.api_key
            }
            
            params = {
                'q': query,
                'count': 10,
                'offset': 0,
                'mkt': 'en-US',
                'safesearch': 'moderate'
            }
            
            response = requests.get(self.base_url, headers=headers, params=params)
            response.raise_for_status()
            
            return response.json()
        except Exception as e:
            print(f"Search error: {str(e)}")
            return None
    
    def _extract_tab_urls(self, response):
        """Extract tab URLs from search results"""
        urls = []
        
        if 'web' in response and 'results' in response['web']:
            for result in response['web']['results']:
                url = result.get('url', '')
                if self._is_tab_site(url):
                    urls.append(url)
        
        return urls
    
    def _is_tab_site(self, url: str):
        """Check if URL is from a known tab site"""
        tab_domains = [
            'ultimate-guitar.com',
            'songsterr.com',
            'guitartabs.cc',
            'tabs.ultimate-guitar.com',
            'guitar.ultimate-guitar.com'
        ]
        
        return any(domain in url.lower() for domain in tab_domains)
    
    def _identify_source(self, url: str):
        """Identify the source of the tab"""
        if 'ultimate-guitar' in url:
            return 'Ultimate Guitar'
        elif 'songsterr' in url:
            return 'Songsterr'
        elif 'guitartabs' in url:
            return 'GuitarTabs'
        else:
            return 'Unknown'
    
    def _fetch_tab_content(self, url: str):
        """Fetch and parse tab content from URL"""
        try:
            headers = {
                'User-Agent': 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36'
            }
            
            response = requests.get(url, headers=headers, timeout=10)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.content, 'html.parser')
            
            # Extract tab content based on source
            if 'ultimate-guitar' in url:
                return self._extract_ultimate_guitar_tab(soup)
            elif 'songsterr' in url:
                return self._extract_songsterr_tab(soup)
            else:
                return self._extract_generic_tab(soup)
                
        except Exception as e:
            print(f"Error fetching tab content from {url}: {str(e)}")
            return None
    
    def _extract_ultimate_guitar_tab(self, soup):
        """Extract tab content from Ultimate Guitar"""
        # Look for tab content in various possible containers
        tab_selectors = [
            '[data-type="tab"]',
            '.js-tab-content',
            '.tab-content',
            '.chord-sheet'
        ]
        
        for selector in tab_selectors:
            tab_element = soup.select_one(selector)
            if tab_element:
                return tab_element.get_text(strip=True)
        
        # Fallback: look for pre-formatted text
        pre_elements = soup.find_all('pre')
        for pre in pre_elements:
            text = pre.get_text(strip=True)
            if len(text) > 50 and any(char in text for char in ['|', 'C', 'D', 'G', 'Am', 'F']):
                return text
        
        return None
    
    def _extract_songsterr_tab(self, soup):
        """Extract tab content from Songsterr"""
        # Songsterr typically has tab data in script tags
        scripts = soup.find_all('script')
        for script in scripts:
            if script.string and 'tab' in script.string.lower():
                # Extract tab data from JavaScript
                content = script.string
                if 'chords' in content or 'notes' in content:
                    return content[:1000]  # Limit size
        
        return None
    
    def _extract_generic_tab(self, soup):
        """Extract tab content from generic tab sites"""
        # Look for common tab patterns
        text_content = soup.get_text()
        
        # Find sections that look like tabs
        lines = text_content.split('\n')
        tab_lines = []
        
        for line in lines:
            line = line.strip()
            if len(line) > 10 and any(pattern in line for pattern in ['|', 'C', 'D', 'G', 'Am', 'F', 'chord']):
                tab_lines.append(line)
        
        if tab_lines:
            return '\n'.join(tab_lines[:20])  # First 20 lines
        
        return None
    
    def _get_mock_tabs(self, song_name: str, num_results: int):
        """Get mock tab data as fallback when API fails"""
        mock_tabs = {
            "happy birthday": [
                {
                    'url': 'https://www.ultimate-guitar.com/happy-birthday-chords',
                    'content': '''Happy Birthday
                    [Verse]
                    C           F
                    Happy birthday to you
                    C           G
                    Happy birthday to you
                    C           F
                    Happy birthday dear friend
                    C           G
                    Happy birthday to you''',
                    'source': 'Ultimate Guitar (Mock)'
                },
                {
                    'url': 'https://www.songsterr.com/happy-birthday',
                    'content': '''Happy Birthday
                    Chords: C, F, G
                    
                    C F C G
                    Happy birthday to you
                    C F C G  
                    Happy birthday to you''',
                    'source': 'Songsterr (Mock)'
                },
                {
                    'url': 'https://www.guitartabs.cc/happy-birthday',
                    'content': '''Happy Birthday - Traditional
                    
                    C F C G
                    Happy birthday to you
                    Happy birthday to you
                    Happy birthday dear [name]
                    Happy birthday to you''',
                    'source': 'GuitarTabs (Mock)'
                }
            ],
            "twinkle twinkle": [
                {
                    'url': 'https://www.ultimate-guitar.com/twinkle-twinkle',
                    'content': '''Twinkle Twinkle Little Star
                    [Verse]
                    C           F
                    Twinkle twinkle little star
                    C           G
                    How I wonder what you are
                    C           F
                    Up above the world so high
                    C           G
                    Like a diamond in the sky
                    
                    [Melody with Duration]
                    C C G G A A G
                    F F E E D D C
                    G G F F E E D
                    G G F F E E D
                    
                    [Chords with Melody and Lyrics]
                    C C G G A A G | F F E E D D C
                    Twinkle twinkle little star
                    G G F F E E D | G G F F E E D  
                    How I wonder what you are
                    C C G G A A G | F F E E D D C
                    Up above the world so high
                    G G F F E E D | G G F F E E D
                    Like a diamond in the sky''',
                    'source': 'Ultimate Guitar (Mock)'
                },
                {
                    'url': 'https://www.songsterr.com/twinkle-twinkle',
                    'content': '''Twinkle Twinkle Little Star
                    Chords: C, F, G
                    
                    C F C G
                    Twinkle twinkle little star
                    How I wonder what you are
                    
                    [Tab]
                    e|--0--0--7--7--9--9--7--|
                    B|--1--1--7--7--9--9--7--|
                    G|--0--0--7--7--9--9--7--|
                    D|--2--2--9--9--11-11-9--|
                    A|--3--3--9--9--11-11-9--|
                    E|--------7--7--9--9--7--|''',
                    'source': 'Songsterr (Mock)'
                }
            ],
            "baby shark": [
                {
                    'url': 'https://www.ultimate-guitar.com/baby-shark',
                    'content': '''Baby Shark
                    [Verse]
                    C           F
                    Baby shark doo doo doo doo doo doo
                    C           G
                    Baby shark doo doo doo doo doo doo
                    C           F
                    Baby shark doo doo doo doo doo doo
                    C           G
                    Baby shark!
                    
                    Mommy shark doo doo doo doo doo doo
                    Mommy shark doo doo doo doo doo doo
                    Mommy shark doo doo doo doo doo doo
                    Mommy shark!
                    
                    [Melody]
                    C C C C C C C
                    F F F F F F F
                    C C C C C C C
                    G G G G G G G
                    
                    [Chords with Melody]
                    C C C C C C C | F F F F F F F
                    Baby shark doo doo doo doo doo doo
                    C C C C C C C | G G G G G G G
                    Baby shark doo doo doo doo doo doo''',
                    'source': 'Ultimate Guitar (Mock)'
                },
                {
                    'url': 'https://www.songsterr.com/baby-shark',
                    'content': '''Baby Shark
                    Chords: C, F, G
                    
                    C F C G
                    Baby shark doo doo doo doo doo doo
                    Baby shark doo doo doo doo doo doo
                    Baby shark doo doo doo doo doo doo
                    Baby shark!
                    
                    [Tab]
                    e|--0--0--0--0--0--0--0--|
                    B|--1--1--1--1--1--1--1--|
                    G|--0--0--0--0--0--0--0--|
                    D|--2--2--2--2--2--2--2--|
                    A|--3--3--3--3--3--3--3--|
                    E|--------0--0--0--0--0--|''',
                    'source': 'Songsterr (Mock)'
                }
            ]
        }
        
        # Try to find exact match first
        song_lower = song_name.lower()
        if song_lower in mock_tabs:
            return mock_tabs[song_lower][:num_results]
        
        # Try partial matches
        for key, tabs in mock_tabs.items():
            if any(word in song_lower for word in key.split()):
                return tabs[:num_results]
        
        # Default fallback
        return mock_tabs["happy birthday"][:num_results]
