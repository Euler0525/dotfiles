---
name: user-python-style
description: User requires strict Python 3 PEP 8 compliance with all-English comments and docstrings
metadata:
  type: user
---

User insists on strict Python 3 coding and commenting conventions:
- All code must conform to **PEP 8** (naming, indentation, imports, line length, etc.).
- All comments, docstrings, variable names, and inline documentation must be in **English only** — no Chinese or other languages.
- Use type hints where appropriate (PEP 484).
- Prefer f-strings over `.format()` or `%` formatting (PEP 498).
- Follow PEP 257 for docstring conventions (one-line or multi-line as appropriate).

**Why:** User enforces a professional, consistent codebase that is accessible to international collaborators and passes linting checks without exceptions.

**How to apply:** When writing or editing any Python file, follow PEP 8 strictly. Write all comments and docstrings in English. Run a mental PEP 8 check before finalizing any Python code.
