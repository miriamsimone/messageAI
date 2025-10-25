import re

class ABCValidator:
    REQUIRED_HEADERS = ['X:', 'T:', 'M:', 'L:', 'K:']
    
    def validate(self, abc_notation: str) -> dict:
        """Validate ABC notation syntax"""
        errors = []
        warnings = []
        
        # Check for required headers
        for header in self.REQUIRED_HEADERS:
            if header not in abc_notation:
                errors.append(f"Missing required header: {header}")
        
        # Check for valid key signature
        if 'K:' in abc_notation:
            key_line = [line for line in abc_notation.split('\n') if line.startswith('K:')][0]
            if not self._validate_key(key_line):
                errors.append(f"Invalid key signature: {key_line}")
        
        # Check for valid time signature
        if 'M:' in abc_notation:
            time_line = [line for line in abc_notation.split('\n') if line.startswith('M:')][0]
            if not self._validate_time(time_line):
                errors.append(f"Invalid time signature: {time_line}")
        
        # Check for basic ABC syntax
        if not self._has_music_content(abc_notation):
            warnings.append("No music content found")
        
        return {
            'is_valid': len(errors) == 0,
            'errors': errors,
            'warnings': warnings
        }
    
    def _validate_key(self, key_line: str) -> bool:
        """Validate key signature"""
        valid_keys = [
            'C', 'G', 'D', 'A', 'E', 'B', 'F#', 'C#', 
            'F', 'Bb', 'Eb', 'Ab', 'Db', 'Gb', 'Cb',
            'Am', 'Em', 'Bm', 'F#m', 'C#m', 'G#m', 'D#m', 'Bbm',
            'Dm', 'Gm', 'Cm', 'Fm', 'Bbm', 'Ebm'
        ]
        
        try:
            key = key_line.split(':')[1].strip().split()[0]
            return key in valid_keys
        except:
            return False
    
    def _validate_time(self, time_line: str) -> bool:
        """Validate time signature"""
        # Match patterns like 4/4, 3/4, 6/8, C, C|
        pattern = r'M:\s*(\d+/\d+|C\|?)'
        return bool(re.match(pattern, time_line))
    
    def _has_music_content(self, abc_notation: str) -> bool:
        """Check if ABC notation has music content"""
        # Look for music lines (not headers)
        lines = abc_notation.split('\n')
        for line in lines:
            line = line.strip()
            if line and not line.startswith(('X:', 'T:', 'M:', 'L:', 'K:')):
                # Check if line contains notes or chords
                if re.search(r'[A-Ga-g]', line) or '"' in line:
                    return True
        return False
    
    def clean_abc(self, abc_notation: str) -> str:
        """Clean and normalize ABC notation"""
        lines = abc_notation.split('\n')
        cleaned_lines = []
        
        for line in lines:
            line = line.strip()
            if line:
                cleaned_lines.append(line)
        
        return '\n'.join(cleaned_lines)
