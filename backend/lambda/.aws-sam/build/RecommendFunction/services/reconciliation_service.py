import openai
import os
import json
import re

class ReconciliationService:
    def __init__(self):
        try:
            # Initialize OpenAI client with minimal parameters
            api_key = os.getenv('OPENAI_API_KEY')
            if not api_key:
                print("OpenAI API key not found")
                self.client = None
                return
            
            # Clear any proxy settings that might interfere
            for proxy_var in ['HTTP_PROXY', 'HTTPS_PROXY', 'http_proxy', 'https_proxy']:
                if proxy_var in os.environ:
                    del os.environ[proxy_var]
                    print(f"Cleared {proxy_var}")
            
            # Initialize with explicit parameters only - try different approaches
            try:
                # First try: minimal initialization
                self.client = openai.OpenAI(api_key=api_key)
            except Exception as e1:
                print(f"First attempt failed: {str(e1)}")
                try:
                    # Second try: with explicit base_url
                    self.client = openai.OpenAI(
                        api_key=api_key,
                        base_url="https://api.openai.com/v1"
                    )
                except Exception as e2:
                    print(f"Second attempt failed: {str(e2)}")
                    # Third try: with explicit timeout
                    self.client = openai.OpenAI(
                        api_key=api_key,
                        timeout=30.0
                    )
            print("OpenAI client initialized successfully")
        except Exception as e:
            print(f"OpenAI client initialization failed: {str(e)}")
            print(f"Error type: {type(e).__name__}")
            import traceback
            print(f"Traceback: {traceback.format_exc()}")
            self.client = None
    
    def reconcile_tabs(self, tabs: list, song_name: str):
        """Reconcile 3 tab versions into ABC notation"""
        
        # Check if OpenAI client is available
        if self.client is None:
            print("OpenAI client not available, using smart fallback ABC notation")
            return self._get_smart_fallback_abc(song_name, tabs)
        
        # Extract approximately the first 16 bars from each tab
        snippets = [self._extract_16_bars(tab['content']) for tab in tabs]
        
        # Create reconciliation prompt
        prompt = self._create_reconciliation_prompt(snippets, song_name, tabs)
        
        try:
            # Get GPT-4 to reconcile
            response = self.client.chat.completions.create(
                model="gpt-4",
                messages=[
                    {"role": "system", "content": "You are a music transcription expert specializing in converting guitar tabs to ABC notation. You excel at reconciling different versions of the same song into a single, accurate representation."},
                    {"role": "user", "content": prompt}
                ],
                temperature=0.2
            )
            
            # Parse ABC notation and confidence
            result_text = response.choices[0].message.content
            abc, confidence = self._parse_result(result_text)
            
            return {
                'abc_notation': abc,
                'confidence': confidence,
                'song_name': song_name,
                'key': self._extract_key_from_abc(abc)
            }
        except Exception as e:
            print(f"OpenAI API call failed: {str(e)}")
            return self._get_smart_fallback_abc(song_name, tabs)
    
    def _extract_16_bars(self, tab_content: str):
        """Extract approximately first 16 bars from tab content"""
        if not tab_content:
            return ""
        
        # Split into lines and take first 120 lines (roughly 16 bars)
        lines = tab_content.split('\n')[:120]
        return '\n'.join(lines)
    
    def _create_reconciliation_prompt(self, snippets, song_name, tabs):
        """Create prompt for GPT-4 reconciliation"""
        
        # Build source information
        source_info = []
        for i, tab in enumerate(tabs):
            source_info.append(f"Source {i+1} ({tab['source']}): {tab['url']}")
        
        template = f"""You are a music transcription expert. You have {len(snippets)} different guitar tab versions of "{song_name}". 
Your job is to reconcile them into a single, accurate version in ABC notation.

{chr(10).join(source_info)}

VERSION 1:
{snippets[0] if len(snippets) > 0 else "No content"}

VERSION 2:
{snippets[1] if len(snippets) > 1 else "No content"}

VERSION 3:
{snippets[2] if len(snippets) > 2 else "No content"}

Instructions:
1. Identify the key signature (most likely C, G, D, or F)
2. Extract the melody for the first 16 bars (continue patterns or phrases to reach 16 bars)
3. Include chord symbols where they appear (in quotes like "C", "G", "Am")
4. Provide at least one lyric line using the ABC lyric syntax (`w:`) that aligns with the melody; if lyrics are missing, create a simple syllable placeholder (e.g., "La") matching note rhythm
5. Output ONLY in ABC notation format
6. Keep it simple - just the main melodic line
7. If versions conflict, use majority consensus or music theory to decide
8. Use standard ABC notation with proper headers

Required ABC format:
X:1
T:{song_name}
M:4/4
L:1/4
K:[key]
[music line with chords and melody spanning 16 bars]
w: [lyrics matching the melody]

Output format (JSON):
{{
    "abc_notation": "X:1\\nT:{song_name}\\nM:4/4\\nL:1/4\\nK:C\\n...",
    "confidence": 0.85,
    "notes": "Brief explanation of any conflicts resolved"
}}"""
        
        return template
    
    def _parse_result(self, result_text: str):
        """Parse JSON response from GPT-4"""
        try:
            # Try to extract JSON from the response
            json_match = re.search(r'\{.*\}', result_text, re.DOTALL)
            if json_match:
                json_str = json_match.group(0)
                result = json.loads(json_str)
                
                abc_notation = result.get('abc_notation', '')
                confidence = result.get('confidence', 0.5)
                
                return abc_notation, confidence
            else:
                # Fallback: try to extract ABC notation directly
                abc_lines = []
                in_abc = False
                for line in result_text.split('\n'):
                    if line.startswith(('X:', 'T:', 'M:', 'L:', 'K:')) or in_abc:
                        in_abc = True
                        abc_lines.append(line)
                        if line.strip() == '' and len(abc_lines) > 5:
                            break
                
                abc_notation = '\n'.join(abc_lines)
                return abc_notation, 0.5
                
        except Exception as e:
            print(f"Error parsing GPT-4 response: {str(e)}")
            # Return a basic ABC notation as fallback
            return f"X:1\nT:Song\nM:4/4\nL:1/4\nK:C\nC D E F |", 0.3
    
    def _extract_key_from_abc(self, abc_notation: str):
        """Extract key signature from ABC notation"""
        for line in abc_notation.split('\n'):
            if line.startswith('K:'):
                return line.split(':')[1].strip()
        return 'C'
    
    def _get_smart_fallback_abc(self, song_name: str, tabs: list):
        """Get smart fallback ABC notation using actual mock data content"""
        # Try to extract real content from the tabs
        if tabs and len(tabs) > 0:
            # Look for actual song content in the tabs
            for tab in tabs:
                content = tab.get('content', '')
                if content and len(content) > 50:  # Has substantial content
                    # Try to create ABC from the actual tab content
                    abc = self._convert_tab_to_abc(content, song_name)
                    if abc:
                        return {
                            'abc_notation': abc,
                            'confidence': 0.4,
                            'song_name': song_name,
                            'key': self._extract_key_from_abc(abc)
                        }
        
        # Fall back to generic ABC if no good content found
        return self._get_fallback_abc(song_name)
    
    def _convert_tab_to_abc(self, tab_content: str, song_name: str):
        """Convert tab content to basic ABC notation"""
        try:
            # Extract chords, lyrics, and melody from tab content
            lines = tab_content.split('\n')
            chords = []
            lyrics = []
            melody_notes = []
            
            print(f"Processing tab content for {song_name}:")
            print(f"Content preview: {tab_content[:200]}...")
            
            in_melody_section = False
            for line in lines:
                line = line.strip()
                if not line or line.startswith('Chords:'):
                    continue
                
                # Check if we're entering a melody section
                if line.startswith('[Melody]') or line.startswith('[Chords with Melody]'):
                    in_melody_section = True
                    continue
                elif line.startswith('[') and not line.startswith('[Melody]') and not line.startswith('[Chords with Melody]'):
                    in_melody_section = False
                    continue
                
                # Extract melody notes if in melody section
                if in_melody_section and re.match(r'^[CFGDAEB][\s]+[CFGDAEB]', line.upper()):
                    # This is a melody line with note sequences (including durations)
                    melody_line = re.findall(r'\b([CFGDAEB][#b]?\d*)\b', line.upper())
                    if melody_line:
                        melody_notes.extend(melody_line)
                        print(f"Found melody: {line} -> {melody_line}")
                    continue
                
                # Look for chord patterns (lines with just chords)
                if re.match(r'^[CFGDAEB][#b]?m?7?\s*$', line.upper()):
                    chords.append(line.upper())
                    print(f"Found chord: {line}")
                # Look for lines with chords and lyrics
                elif any(chord in line.upper() for chord in ['C', 'F', 'G', 'D', 'A', 'E', 'B']):
                    # Extract chords from line
                    chord_matches = re.findall(r'\b([CFGDAEB][#b]?m?7?)\b', line.upper())
                    if chord_matches:
                        chords.extend(chord_matches)
                        print(f"Found chords in line: {line} -> {chord_matches}")
                
                # Check if this line contains melody notes (with or without durations)
                if re.match(r'^[CFGDAEB][\s]+[CFGDAEB]', line.upper()):
                    # This is a melody line with note sequences
                    melody_line = re.findall(r'\b([CFGDAEB][#b]?\d*)\b', line.upper())
                    if melody_line:
                        melody_notes.extend(melody_line)
                        print(f"Found melody notes: {line} -> {melody_line}")
                    continue
                
                # Look for lyric patterns (lines with actual words, not just chords or melody notes)
                # A line is lyrics if it has words and is not just chord symbols or melody notes
                if (len(line) > 5 and 
                    not re.match(r'^[CFGDAEB\s#b]+$', line.upper()) and 
                    any(char.isalpha() for char in line) and
                    # Check if it's not just chord symbols with spaces
                    not re.match(r'^[CFGDAEB][\s]+[CFGDAEB]', line.upper()) and
                    # Check if it's not melody notes with durations (like C2 C2 G2 G2)
                    not re.match(r'^[CFGDAEB]\d+[\s]+[CFGDAEB]\d+', line.upper())):
                    # This is likely lyrics
                    lyrics.append(line)
                    print(f"Found lyrics: {line}")
            
            print(f"Extracted chords: {chords}")
            print(f"Extracted lyrics: {lyrics}")
            print(f"Extracted melody: {melody_notes}")
            
            # Validate note durations add up to 4 beats per bar (4/4 time signature)
            if melody_notes:
                self._validate_note_durations(melody_notes)
            
            # Create basic ABC notation with real lyrics and melody
            abc_lines = [
                f"X:1",
                f"T:{song_name}",
                "M:4/4",
                "L:1/4",
                "K:C"
            ]
            
            # Use actual melody if available, otherwise fallback to generic
            if melody_notes:
                print(f"Using actual melody: {melody_notes}")
                
                # Create complete lyrics for the entire song
                complete_lyrics = []
                if lyrics:
                    # Use all available lyrics
                    complete_lyrics = lyrics
                    # If we have fewer than 4 lines, repeat the last line
                    while len(complete_lyrics) < 4:
                        complete_lyrics.append(complete_lyrics[-1] if complete_lyrics else "La la la la")
                else:
                    complete_lyrics = ["La la la la"] * 4
                
                # Create 4 lines of 4 bars each (16 total bars)
                for line_idx in range(4):
                    chord = chords[line_idx % len(chords)] if chords else "C"
                    
                    # Use actual melody notes for this line
                    if melody_notes:
                        # Take 16 notes from the melody, cycling if needed
                        line_melody = (melody_notes * 4)[:16]  # Repeat melody to get 16 notes
                        # Group into 4 bars of 4 notes each
                        bars = []
                        for bar_idx in range(4):
                            bar_notes = line_melody[bar_idx*4:(bar_idx+1)*4]
                            # Ensure notes have proper duration (default to quarter notes if no duration specified)
                            formatted_notes = []
                            for note in bar_notes:
                                if note.isdigit() or note.endswith(('2', '4', '8')):
                                    # Note already has duration
                                    formatted_notes.append(note)
                                else:
                                    # Add default quarter note duration
                                    formatted_notes.append(note)
                            bar_str = ' '.join(formatted_notes)
                            bars.append(bar_str)
                        melody_line = ' | '.join(bars) + ' |'
                        abc_lines.append(f'"{chord}"{melody_line}')
                    else:
                        # Fallback to generic melody
                        abc_lines.append(f'"{chord}"C D E F | "F"G A B c | "G"d e f g | "C"a4 |')
                    
                    # Add complete lyrics for this line
                    lyric_line = complete_lyrics[line_idx] if line_idx < len(complete_lyrics) else "La la la la"
                    words = lyric_line.split()
                    
                    # Create lyrics for all 4 bars of this line
                    if len(words) >= 4:
                        # Split words into 4 bars
                        bar_words = [words[i:i+4] for i in range(0, len(words), 4)][:4]
                        lyric_bars = []
                        for bar in bar_words:
                            if len(bar) == 4:
                                lyric_bars.append(' '.join(bar))
                            else:
                                # Pad with "la" if not enough words
                                padded_bar = bar + ['la'] * (4 - len(bar))
                                lyric_bars.append(' '.join(padded_bar))
                        abc_lines.append(f"w: {' | '.join(lyric_bars)} |")
                    else:
                        # If not enough words, repeat the line across bars
                        repeated_words = (words * 4)[:16]  # Repeat to get 16 words
                        bar_words = [repeated_words[i:i+4] for i in range(0, 16, 4)]
                        lyric_bars = [' '.join(bar) for bar in bar_words]
                        abc_lines.append(f"w: {' | '.join(lyric_bars)} |")
            else:
                # Fallback to generic melody and lyrics
                print("No melody found, using generic C major scale")
                lyric_lines = lyrics[:4] if len(lyrics) >= 4 else lyrics + ["La la la la"] * (4 - len(lyrics))
                
                for i, lyric_line in enumerate(lyric_lines):
                    chord = chords[i % len(chords)] if chords else "C"
                    abc_lines.append(f'"{chord}"C D E F | "F"G A B c | "G"d e f g | "C"a4 |')
                    
                    # Split lyric line into words for the 4 bars
                    words = lyric_line.split()
                    if len(words) >= 4:
                        bar_words = [words[i:i+4] for i in range(0, len(words), 4)][:4]
                        lyric_bars = []
                        for bar in bar_words:
                            if len(bar) == 4:
                                lyric_bars.append(' '.join(bar))
                            else:
                                lyric_bars.append(' '.join(bar) + ' ' + ' '.join(['la'] * (4 - len(bar))))
                        abc_lines.append(f"w: {' | '.join(lyric_bars)} |")
                    else:
                        # Pad with "la" if not enough words
                        padded_words = words + ['la'] * (16 - len(words))
                        bar_words = [padded_words[i:i+4] for i in range(0, 16, 4)]
                        lyric_bars = [' '.join(bar) for bar in bar_words]
                        abc_lines.append(f"w: {' | '.join(lyric_bars)} |")
            
            return '\n'.join(abc_lines)
        
        except Exception as e:
            print(f"Error converting tab to ABC: {str(e)}")
        
        return None
    
    def _validate_note_durations(self, melody_notes: list):
        """Validate that note durations add up to 4 beats per bar (4/4 time signature)"""
        try:
            # Group notes into bars of 4 notes each
            bars = []
            for i in range(0, len(melody_notes), 4):
                bar = melody_notes[i:i+4]
                if len(bar) == 4:  # Only validate complete bars
                    bars.append(bar)
            
            print(f"Validating {len(bars)} complete bars...")
            
            for bar_idx, bar in enumerate(bars):
                total_beats = 0
                bar_notes = []
                
                for note in bar:
                    # Parse note duration
                    beats = self._get_note_duration_beats(note)
                    total_beats += beats
                    bar_notes.append(f"{note}({beats})")
                
                print(f"Bar {bar_idx + 1}: {' '.join(bar_notes)} = {total_beats} beats")
                
                if total_beats != 4.0:
                    print(f"⚠️  WARNING: Bar {bar_idx + 1} has {total_beats} beats instead of 4.0")
                    # Suggest corrections
                    self._suggest_bar_corrections(bar, total_beats)
                else:
                    print(f"✅ Bar {bar_idx + 1} is correct (4 beats)")
            
        except Exception as e:
            print(f"Error validating note durations: {str(e)}")
    
    def _get_note_duration_beats(self, note: str) -> float:
        """Convert ABC note to beat count"""
        # Remove note name, keep only duration
        duration = re.sub(r'^[CFGDAEB][#b]?', '', note.upper())
        
        if not duration:  # No duration specified (default quarter note)
            return 1.0
        elif duration == '2':  # Half note
            return 2.0
        elif duration == '4':  # Quarter note
            return 1.0
        elif duration == '8':  # Eighth note
            return 0.5
        elif duration == '16':  # Sixteenth note
            return 0.25
        elif '/' in duration:  # Dotted notes
            base_duration = duration.split('/')[0]
            if base_duration == '2':
                return 3.0  # Dotted half note
            elif base_duration == '4':
                return 1.5  # Dotted quarter note
        else:
            # Try to parse as number
            try:
                num = float(duration)
                return 4.0 / num  # 4/4 time signature
            except:
                return 1.0  # Default to quarter note
    
    def _suggest_bar_corrections(self, bar: list, current_beats: float):
        """Suggest corrections for bars that don't add up to 4 beats"""
        target_beats = 4.0
        difference = target_beats - current_beats
        
        print(f"   💡 Suggestion: Need to {'add' if difference > 0 else 'remove'} {abs(difference)} beats")
        
        if difference > 0:
            # Need to add beats - suggest longer notes
            if difference == 1.0:
                print(f"   Try changing one note to half note (2 beats)")
            elif difference == 2.0:
                print(f"   Try changing one note to whole note (4 beats)")
        else:
            # Need to remove beats - suggest shorter notes
            if abs(difference) == 1.0:
                print(f"   Try changing one note to eighth note (0.5 beats)")
            elif abs(difference) == 2.0:
                print(f"   Try changing two notes to eighth notes (0.5 beats each)")
    
    def _get_fallback_abc(self, song_name: str):
        """Get fallback ABC notation when OpenAI is not available"""
        # Simple fallback ABC notation spanning 16 bars with placeholder lyrics
        fallback_abc = f"""X:1
T:{song_name}
M:4/4
L:1/4
K:C
"C"C D E F | "F"G A B c | "G"d e f g | "C"a g f e |
w: La la la la | La la la la | La la la la | La la la la |
"C"C D E F | "F"G A B c | "G"d e f g | "C"a4 |
w: La la la la | La la la la | La la la la | La la laaa |
"C"C D E F | "F"G A B c | "G"d e f g | "C"a g f e |
w: La la la la | La la la la | La la la la | La la la la |
"C"C D E F | "F"G A B c | "G"d e f g | "C"c4 |
w: La la la la | La la la la | La la la la | La la laaa |"""
        
        return {
            'abc_notation': fallback_abc,
            'confidence': 0.3,
            'song_name': song_name,
            'key': 'C'
        }
