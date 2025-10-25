import json
import os
from services.mock_search_service import MockSearchService
from services.reconciliation_service import ReconciliationService
from utils.abc_utils import ABCValidator

def handler(event, context):
    """Test version of generate_sheet using mock data"""
    
    try:
        # Parse request
        body = json.loads(event['body'])
        song_name = body['song_name']
        instrument = body.get('instrument', 'C')  # Default concert pitch
        
        print(f"Testing with mock data for: {song_name}, instrument: {instrument}")
        
        # Step 1: Use mock search service
        search_service = MockSearchService()
        tabs = search_service.search_tabs(song_name)
        
        if len(tabs) < 2:
            return {
                'statusCode': 404,
                'headers': {
                    'Content-Type': 'application/json',
                    'Access-Control-Allow-Origin': '*'
                },
                'body': json.dumps({
                    'error': 'No mock tabs found',
                    'message': f'Could not find mock tab data for "{song_name}"'
                })
            }
        
        print(f"Found {len(tabs)} mock tab sources")
        
        # Step 2: Reconcile tabs using real GPT-4
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
                'sources': [tab['url'] for tab in tabs[:3]],
                'test_mode': True
            })
        }
    
    except Exception as e:
        print(f"Error in test_generate_sheet: {str(e)}")
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
