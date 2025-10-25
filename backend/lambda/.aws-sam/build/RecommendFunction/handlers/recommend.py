import json

def handler(event, context):
    """Generate music recommendations based on chat history"""
    
    try:
        # Parse request
        body = json.loads(event['body'])
        chat_history = body.get('chat_history', [])
        
        print(f"Generating recommendations based on {len(chat_history)} messages")
        
        # For demo, return mock recommendations
        recommendations = [
            {
                'title': 'Similar Classical Piece',
                'composer': 'Wolfgang Amadeus Mozart',
                'description': 'Based on your interest in classical music',
                'abc_preview': 'X:1\nT:Recommendation\nM:4/4\nK:C\nC D E F | G A B c |'
            }
        ]
        
        return {
            'statusCode': 200,
            'headers': {
                'Content-Type': 'application/json',
                'Access-Control-Allow-Origin': '*'
            },
            'body': json.dumps({
                'status': 'success',
                'recommendations': recommendations,
                'reasoning': 'Based on your chat history, here are some recommendations'
            })
        }
    
    except Exception as e:
        print(f"Error in recommend: {str(e)}")
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
