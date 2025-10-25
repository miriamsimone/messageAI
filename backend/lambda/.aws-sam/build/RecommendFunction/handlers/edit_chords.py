import json

def handler(event, context):
    """Edit chord symbols using natural language"""
    
    try:
        # Parse request
        body = json.loads(event['body'])
        abc_notation = body['abc_notation']
        edit_instruction = body['instruction']
        
        print(f"Editing chords: {edit_instruction}")
        
        # For demo, return the same ABC notation
        # In production, this would use AI to parse the instruction and modify the ABC
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'status': 'success',
                'abc_notation': abc_notation,
                'message': f'Applied edit: {edit_instruction}'
            })
        }
    
    except Exception as e:
        print(f"Error in edit_chords: {str(e)}")
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
