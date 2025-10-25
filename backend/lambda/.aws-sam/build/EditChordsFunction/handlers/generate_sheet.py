import json
import os
import re
from services.search_service import SearchService
from services.reconciliation_service import ReconciliationService
from utils.abc_utils import ABCValidator

def extract_song_name(user_input):
    """Extract clean song name from user input using improved AI"""
    
    try:
        # Use OpenAI with better prompt
        import openai
        
        # Clear any proxy settings that might interfere
        for proxy_var in ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy']:
            if proxy_var in os.environ:
                del os.environ[proxy_var]
                print(f"Cleared {proxy_var}")
        
        client = openai.OpenAI(api_key=os.getenv('OPENAI_API_KEY'))
        
        # Improved prompt with better examples and constraints
        prompt = f"""Extract the song name from this user request. Return ONLY the song name.

Examples:
- "Get me the music for baby shark" → "Baby Shark"
- "Can you find me happy birthday" → "Happy Birthday" 
- "Play me twinkle twinkle little star" → "Twinkle Twinkle Little Star"
- "I want to hear let it go from frozen" → "Let It Go"
- "Show me sheet music for jingle bells" → "Jingle Bells"

Rules:
1. Extract ONLY the song name
2. Use proper title case
3. Remove all request language
4. If no clear song, return "Unknown"

User request: "{user_input}"

Song name:"""

        response = client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=[
                {"role": "system", "content": "Extract song names from user requests. Return only the song name, properly capitalized."},
                {"role": "user", "content": prompt}
            ],
            temperature=0.1,
            max_tokens=20
        )
        
        song_name = response.choices[0].message.content.strip()
        
        # Clean up the response
        song_name = song_name.replace('"', '').replace("'", '').strip()
        
        # Validate the response
        if song_name and len(song_name) > 1 and len(song_name) < 50 and song_name != "Unknown":
            print(f"AI extracted: '{song_name}'")
            return song_name
        else:
            print(f"AI extraction failed: '{song_name}'")
            
    except Exception as e:
        print(f"AI song name extraction failed: {str(e)}")
    
    # Fallback to simple regex-based extraction
    return extract_song_name_fallback(user_input)

def extract_song_name_fallback(user_input):
    """Fallback regex-based song name extraction"""
    
    # Common patterns to remove
    patterns_to_remove = [
        r'get me the music for',
        r'get me music for',
        r'find me the music for',
        r'find me music for',
        r'play me the music for',
        r'play me music for',
        r'give me the music for',
        r'give me music for',
        r'can you get me the music for',
        r'can you find me the music for',
        r'can you play me the music for',
        r'can you give me the music for',
        r'please get me the music for',
        r'please find me the music for',
        r'please play me the music for',
        r'please give me the music for',
        r'i want the music for',
        r'i want music for',
        r'i need the music for',
        r'i need music for',
        r'show me the music for',
        r'show me music for',
        r'generate the music for',
        r'generate music for',
        r'create the music for',
        r'create music for',
        r'make the music for',
        r'make music for',
        r'get me',
        r'find me',
        r'play me',
        r'give me',
        r'show me',
        r'generate',
        r'create',
        r'make',
        r'music for',
        r'the music for',
        r'for the song',
        r'for song',
        r'song called',
        r'song named',
        r'the song',
        r'song',
        r'please',
        r'can you',
        r'could you',
        r'would you',
        r'will you'
    ]
    
    # Clean the input
    clean_input = user_input.lower().strip()
    
    # Remove common patterns
    for pattern in patterns_to_remove:
        clean_input = re.sub(pattern, '', clean_input, flags=re.IGNORECASE).strip()
    
    # Remove extra whitespace
    clean_input = re.sub(r'\s+', ' ', clean_input).strip()
    
    # If nothing left, return original
    if not clean_input:
        return user_input
    
    # Capitalize first letter of each word
    clean_input = ' '.join(word.capitalize() for word in clean_input.split())
    
    return clean_input

def is_classical_music_search(song_name):
    """Detect if this is a classical music search"""
    classical_keywords = [
        'moonlight sonata', 'beethoven', 'bach', 'chopin', 'mozart', 'brahms',
        'schubert', 'schumann', 'liszt', 'debussy', 'ravel', 'tchaikovsky',
        'rachmaninoff', 'prokofiev', 'shostakovich', 'stravinsky', 'bartok',
        'sonata', 'concerto', 'symphony', 'nocturne', 'prelude', 'fugue',
        'etude', 'waltz', 'mazurka', 'polonaise', 'impromptu', 'ballade',
        'classical', 'baroque', 'romantic', 'impressionist'
    ]
    
    song_lower = song_name.lower()
    return any(keyword in song_lower for keyword in classical_keywords)

def handle_classical_search(song_name):
    """Handle classical music search by calling IMSLP"""
    try:
        # Import the Mutopia search function
        from handlers.search_imslp import search_imslp
        
        # Search Mutopia Project using Brave Search
        mutopia_results = search_imslp(song_name)
        
        if not mutopia_results:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'No classical music found',
                    'message': f'No classical music found for "{song_name}"'
                })
            }
        
        # Get first result
        first_result = mutopia_results[0]
        
        # Return in the same format as tab search but with classical music data
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'status': 'success',
                'classical_music': True,
                'pdf_url': first_result.get('pdf_url', ''),
                'title': first_result.get('title', 'Unknown'),
                'composer': first_result.get('composer', 'Unknown'),
                'opus': first_result.get('opus', ''),
                'mutopia_url': first_result.get('mutopia_url', ''),
                'description': first_result.get('description', ''),
                'message': f'Found classical music: {first_result.get("title", "Unknown")} by {first_result.get("composer", "Unknown")}',
                'sources': [first_result.get('mutopia_url', '')]
            })
        }
        
    except Exception as e:
        print(f"Error in classical search: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Error searching classical music'
            })
        }

def handler(event, context):
    """Generate sheet music ABC notation from song name"""
    
    try:
        # Parse request
        body = json.loads(event['body'])
        raw_song_name = body['song_name']
        instrument = body.get('instrument', 'C')  # Default concert pitch
        
        # Extract clean song name from user input
        song_name = extract_song_name(raw_song_name)
        
        # Check if this is a classical music search
        if is_classical_music_search(song_name):
            print(f"Detected classical music search: {song_name}")
            return handle_classical_search(song_name)
        
        print(f"Generating sheet music for: {song_name}, instrument: {instrument}")
        
        # Step 1: Search for tabs
        search_service = SearchService()
        tabs = search_service.search_tabs(song_name)
        
        if len(tabs) < 2:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'No tabs found',
                    'message': f'Could not find enough tab sources for "{song_name}"'
                })
            }
        
        print(f"Found {len(tabs)} tab sources")
        
        # Step 2: Reconcile tabs
        reconciliation_service = ReconciliationService()
        result = reconciliation_service.reconcile_tabs(tabs, song_name)
        
        abc_notation = result['abc_notation']
        confidence = result['confidence']
        key = result['key']
        
        print(f"Reconciled with confidence: {confidence}")
        
        # Step 3: Validate ABC notation
        validator = ABCValidator()
        validation = validator.validate(abc_notation)
        
        if not validation['is_valid']:
            print(f"ABC validation failed: {validation['errors']}")
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Generated invalid ABC notation',
                    'validation_errors': validation['errors']
                })
            }
        
        # Step 4: Transpose if needed (will implement in next phase)
        # For now, skip transposition
        
        # Clean up ABC notation
        cleaned_abc = validator.clean_abc(abc_notation)
        
        # Return success
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'status': 'success',
                'abc_notation': cleaned_abc,
                'confidence': confidence,
                'key': key,
                'original_key': key,
                'transposed_to': instrument if instrument != 'C' else None,
                'sources': [tab['url'] for tab in tabs[:3]]
            })
        }
    
    except Exception as e:
        print(f"Error in generate_sheet: {str(e)}")
        return {
            'statusCode': 500,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'error': str(e),
                'message': 'Internal server error'
            })
        }
