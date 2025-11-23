#!/usr/bin/env python3
"""
Generate UUID v7 for OpenSensor Space station ID

UUID v7 is time-ordered and includes timestamp information,
making it ideal for time-series sensor data.
"""

import sys

def generate_uuid7():
    """
    Generate UUID v7 with fallback support for older Python versions.

    Returns:
        str: UUID v7 string
    """
    try:
        # Try Python 3.12+ native uuid7
        import uuid
        if hasattr(uuid, 'uuid7'):
            return str(uuid.uuid7())
    except Exception:
        pass

    try:
        # Try uuid-utils library
        from uuid_utils import uuid7
        return str(uuid7())
    except ImportError:
        print("Error: uuid-utils library not installed.", file=sys.stderr)
        print("Install with: pip install uuid-utils", file=sys.stderr)
        print("Or upgrade to Python 3.12+ for native support", file=sys.stderr)
        sys.exit(1)

if __name__ == "__main__":
    print(generate_uuid7())
