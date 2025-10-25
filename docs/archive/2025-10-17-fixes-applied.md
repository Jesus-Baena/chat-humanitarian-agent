# Fixes Applied - October 17, 2025 (Archived)

Summary of production fixes and improvements. For up-to-date processes, see `docs/guides/*`.

Sanitized test call:
```bash
curl -X POST "${FLOWISE_URL}/api/v1/prediction/<chatflow-id>" \
  -H "Authorization: Bearer YOUR_FLOWISE_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"question": "test"}'
```
