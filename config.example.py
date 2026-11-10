#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Example configuration file for API settings
Copy this file to config.py. Credentials are read from environment variables
or from a .env file next to this file (do NOT commit .env), e.g.:

    API_KEY=your-api-key-here
"""

import os
from pathlib import Path


def _load_dotenv(path=Path(__file__).with_name(".env")):
    """Minimal .env loader (KEY=VALUE per line). Real environment variables take precedence."""
    if not path.exists():
        return
    raw = path.read_bytes()
    # PowerShell 5.1 "echo ... > .env" writes UTF-16; handle it as well as UTF-8
    text = raw.decode("utf-16") if raw[:2] in (b"\xff\xfe", b"\xfe\xff") else raw.decode("utf-8-sig")
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        os.environ.setdefault(key.strip(), value.strip().strip('"').strip("'"))


_load_dotenv()

# API Configuration
API_BASE_URL = os.environ.get("API_BASE_URL", "https://zlegl6sgdl.execute-api.eu-central-1.amazonaws.com/prod")
API_KEY = os.environ.get("API_KEY", "")

# Default settings
DEFAULT_BATCH_SIZE = 5
DEFAULT_NUM_BATCHES = 2
DEFAULT_OUTPUT_DIR = "md_export"
DEFAULT_INPUT_FILE = "raw.json"
