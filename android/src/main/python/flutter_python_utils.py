# Flutter Python Bridge Utilities
import sys
import io
import traceback
import json
import math
import datetime
import os
import importlib
from contextlib import redirect_stdout, redirect_stderr

# Try to import common packages
try:
    import numpy as np
except ImportError:
    pass

try:
    import pandas as pd
except ImportError:
    pass

try:
    import matplotlib.pyplot as plt
except ImportError:
    pass

class CaptureOutput:
    """Context manager to capture stdout and stderr."""
    def __init__(self):
        self.stdout = io.StringIO()
        self.stderr = io.StringIO()
        self.output = ""
        self.error = ""
    
    def __enter__(self):
        sys.stdout = self.stdout
        sys.stderr = self.stderr
        return self
    
    def __exit__(self, exc_type, exc_val, exc_tb):
        sys.stdout = sys.__stdout__
        sys.stderr = sys.__stderr__
        self.output = self.stdout.getvalue()
        self.error = self.stderr.getvalue()

def run_code(code, globals_dict=None, locals_dict=None):
    """Run Python code and capture output and errors."""
    if globals_dict is None:
        globals_dict = {}
    if locals_dict is None:
        locals_dict = {}
    
    # Add builtins to globals
    if '__builtins__' not in globals_dict:
        globals_dict['__builtins__'] = __builtins__
    
    # Add common modules to globals
    globals_dict['math'] = math
    globals_dict['datetime'] = datetime
    globals_dict['os'] = os
    globals_dict['json'] = json
    globals_dict['sys'] = sys
    
    # Try to add other common modules
    try:
        globals_dict['np'] = np
    except NameError:
        pass
    
    try:
        globals_dict['pd'] = pd
    except NameError:
        pass
    
    try:
        globals_dict['plt'] = plt
    except NameError:
        pass
    
    result = {
        'success': False,
        'output': '',
        'error': '',
        'return_value': None
    }
    
    with CaptureOutput() as capture:
        try:
            # First try to evaluate as an expression
            try:
                return_value = eval(code, globals_dict, locals_dict)
                result['return_value'] = return_value
                result['success'] = True
            except SyntaxError:
                # If it's not an expression, execute as a statement
                exec(code, globals_dict, locals_dict)
                result['success'] = True
        except Exception as e:
            result['error'] = f"{type(e).__name__}: {str(e)}\n{traceback.format_exc()}"
    
    result['output'] = capture.output
    if not result['error'] and capture.error:
        result['error'] = capture.error
    
    return result

def run_script(script_path, globals_dict=None):
    """Run a Python script file and capture output and errors."""
    if globals_dict is None:
        globals_dict = {'__name__': '__main__'}
    
    # Add builtins to globals
    if '__builtins__' not in globals_dict:
        globals_dict['__builtins__'] = __builtins__
    
    result = {
        'success': False,
        'output': '',
        'error': ''
    }
    
    with CaptureOutput() as capture:
        try:
            with open(script_path, 'r') as f:
                script_content = f.read()
            
            # Add script directory to sys.path
            import os
            script_dir = os.path.dirname(os.path.abspath(script_path))
            if script_dir not in sys.path:
                sys.path.insert(0, script_dir)
            
            # Execute the script
            exec(script_content, globals_dict)
            result['success'] = True
        except Exception as e:
            result['error'] = f"{type(e).__name__}: {str(e)}\n{traceback.format_exc()}"
    
    result['output'] = capture.output
    if not result['error'] and capture.error:
        result['error'] = capture.error
    
    return result
