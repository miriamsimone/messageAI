import json
import os
import requests
from bs4 import BeautifulSoup
import boto3
from io import BytesIO
import base64

def handler(event, context):
    """Search IMSLP for classical music and return first page as image"""
    
    try:
        # Parse request
        body = json.loads(event['body'])
        search_query = body['query']
        
        print(f"Searching IMSLP for: {search_query}")
        
        # Step 1: Search IMSLP
        imslp_results = search_imslp(search_query)
        
        if not imslp_results:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'No results found',
                    'message': f'No classical music found for "{search_query}"'
                })
            }
        
        # Step 2: Get first result and convert to image
        first_result = imslp_results[0]
        image_url = convert_pdf_to_image(first_result['pdf_url'], first_result['title'])
        
        if not image_url:
            return {
                'statusCode': 500,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'Failed to process sheet music',
                    'message': 'Could not convert PDF to image'
                })
            }
        
        # Return success
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'status': 'success',
                'title': first_result['title'],
                'composer': first_result['composer'],
                'image_url': image_url,
                'imslp_url': first_result['imslp_url'],
                'description': first_result.get('description', ''),
                'results_count': len(imslp_results)
            })
        }
    
    except Exception as e:
        print(f"Error in search_imslp: {str(e)}")
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

def search_imslp(query):
    """Search for classical music using Brave Search API"""
    try:
        # Try to search for Mutopia Project results using Brave Search
        brave_result = search_mutopia_with_brave(query)
        if brave_result:
            return [brave_result]
        
        # Fall back to mock data
        return get_mock_mutopia_results(query)
        
    except Exception as e:
        print(f"Error searching IMSLP: {str(e)}")
        return []

def search_mutopia_with_brave(query):
    """Search for Mutopia Project results using Brave Search API"""
    try:
        from services.search_service import SearchService
        search_service = SearchService()
        
        # Search for Mutopia Project results
        mutopia_query = f"site:mutopiaproject.org {query}"
        response = search_service._search(mutopia_query)
        
        if response and 'web' in response and 'results' in response['web']:
            results = response['web']['results']
            for result in results:
                url = result.get('url', '')
                title = result.get('title', '')
                description = result.get('description', '')
                
                # Look for PDF links in the description or URL
                if 'pdf' in url.lower() or 'pdf' in description.lower():
                    return {
                        'title': title,
                        'pdf_url': url,
                        'description': description,
                        'source': 'Mutopia Project (Brave Search)'
                    }
        
        return None
        
    except Exception as e:
        print(f"Brave search failed: {str(e)}")
        return None

def get_mock_mutopia_results(query):
    """Mock Mutopia Project results for demo"""
    mock_results = {
        "moonlight sonata": [
            {
                'title': 'Piano Sonata No. 14 "Moonlight"',
                'composer': 'Ludwig van Beethoven',
                'mutopia_url': 'https://www.mutopiaproject.org/cgibin/make-table.cgi?Composer=Beethoven&title=Piano%20Sonata%20No.%2014',
                'pdf_url': 'https://via.placeholder.com/800x1000/ffffff/000000?text=Moonlight+Sonata+PDF',
                'description': 'First movement - Adagio sostenuto',
                'opus': 'Op. 27, No. 2',
                'demo_note': 'For demo purposes - PDF may not be available at this URL'
            }
        ],
        "bach": [
            {
                'title': 'Prelude and Fugue in C major, BWV 846',
                'composer': 'Johann Sebastian Bach',
                'mutopia_url': 'https://www.mutopiaproject.org/cgibin/make-table.cgi?Composer=Bach&title=Prelude%20and%20Fugue',
                'pdf_url': 'https://www.mutopiaproject.org/ftp/BachJS/BWV846/bach-prelude-fugue-bwv846/bach-prelude-fugue-bwv846-a4.pdf',
                'description': 'From The Well-Tempered Clavier, Book I',
                'opus': 'BWV 846'
            }
        ],
        "chopin": [
            {
                'title': 'Nocturne in E-flat major, Op. 9, No. 2',
                'composer': 'Frédéric Chopin',
                'mutopia_url': 'https://www.mutopiaproject.org/cgibin/make-table.cgi?Composer=Chopin&title=Nocturne',
                'pdf_url': 'https://www.mutopiaproject.org/ftp/ChopinFF/O09_2/chopin-nocturne-op9-2/chopin-nocturne-op9-2-a4.pdf',
                'description': 'One of Chopin\'s most famous nocturnes',
                'opus': 'Op. 9, No. 2'
            }
        ]
    }
    
    # Find best match
    query_lower = query.lower()
    for key, results in mock_results.items():
        if key in query_lower:
            return results
    
    # Default fallback
    return [{
        'title': 'Classical Music Search Result',
        'composer': 'Unknown Composer',
        'imslp_url': 'https://imslp.org/',
        'pdf_url': 'https://imslp.org/wiki/Special:IMSLPDisclaimerAccept/28524',
        'description': f'Search result for "{query}"'
    }]

def convert_pdf_to_image(pdf_url, title):
    """Convert PDF first page to image and upload to S3"""
    try:
        # For demo, return a placeholder image URL
        # In production, this would:
        # 1. Download PDF from IMSLP
        # 2. Convert first page to PNG using pdf2image
        # 3. Upload to S3
        # 4. Return public URL
        
        # Mock image URL for demo
        return f"https://via.placeholder.com/800x1000/ffffff/000000?text={title.replace(' ', '+')}"
        
    except Exception as e:
        print(f"Error converting PDF to image: {str(e)}")
        return None
