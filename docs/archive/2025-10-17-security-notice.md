# Security Notice - API Key Exposure (Archived, Sanitized)

An API key was previously exposed in history. The key has been rotated.

- Service: Flowise
- Key: YOUR_FLOWISE_API_KEY (masked)
- Endpoint: https://<your-flowise-host>/api/v1/prediction/<chatflow-id>

Actions taken:
- Removed hardcoded key from working tree
- Rotated the key in the provider and GitHub Secrets
- Guidance updated to use placeholders and environment variables

If performing history cleanup, consider repository history rewriting. Coordinate with collaborators before force-pushing.
