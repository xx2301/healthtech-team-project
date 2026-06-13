Document all security issues with severity ratings:

| # | Severity | Issue |
|---|----------|-------|
| 1 | CRITICAL | `.env` with OpenAI API key, MongoDB passwords, email credentials committed to git |
| 2 | CRITICAL | `node_modules` committed to repo |
| 3 | CRITICAL | Password logged in plaintext in `routes/auth.js` |
| 4 | HIGH | CORS `origin: '*'` with credentials enabled |
| 5 | HIGH | No rate limiting despite `express-rate-limit` dependency |
| 6 | HIGH | Hardcoded JWT fallback secret `'your-secret-key'` |
| 7 | MEDIUM | `bcrypt` and `bcryptjs` both in dependencies (redundant) |
| 8 | MEDIUM | Regex search without sanitization (NoSQL injection risk) |
| 9 | LOW | MongoDB connection string hardcoded as fallback in server.js |