import json

class MockSearchService:
    """Mock search service for testing when API rate limits are hit"""
    
    def search_tabs(self, song_name: str, num_results: int = 3):
        """Return mock tab data for testing"""
        
        # Mock tab data for common songs
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
                    'source': 'Ultimate Guitar'
                },
                {
                    'url': 'https://www.songsterr.com/happy-birthday',
                    'content': '''Happy Birthday
                    Chords: C, F, G
                    
                    C F C G
                    Happy birthday to you
                    C F C G  
                    Happy birthday to you''',
                    'source': 'Songsterr'
                },
                {
                    'url': 'https://www.guitartabs.cc/happy-birthday',
                    'content': '''Happy Birthday - Traditional
                    
                    C F C G
                    Happy birthday to you
                    Happy birthday to you
                    Happy birthday dear [name]
                    Happy birthday to you''',
                    'source': 'GuitarTabs'
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
                    Like a diamond in the sky''',
                    'source': 'Ultimate Guitar'
                },
                {
                    'url': 'https://www.songsterr.com/twinkle-twinkle',
                    'content': '''Twinkle Twinkle Little Star
                    Chords: C, F, G
                    
                    C F C G
                    Twinkle twinkle little star
                    How I wonder what you are''',
                    'source': 'Songsterr'
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
