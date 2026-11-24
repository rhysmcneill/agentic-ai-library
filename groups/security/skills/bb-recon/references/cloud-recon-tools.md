# Cloud Recon Tools — Installation and Setup

## Go-based Tools

Install all Go tools at once:

```bash
go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest
go install github.com/projectdiscovery/httpx/cmd/httpx@latest
go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest
go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
go install github.com/ffuf/ffuf/v2@latest
go install github.com/lc/gau/v2/cmd/gau@latest
go install github.com/tomnomnom/waybackurls@latest
go install github.com/michenriksen/aquatone@latest
```

Verify installations:
```bash
subfinder -version && httpx -version && nuclei -version
```

Update nuclei templates after install:
```bash
nuclei -update-templates
```

## Python-based Tools

```bash
pip install cloud-enum trufflehog
```

## Wordlists

```bash
git clone https://github.com/danielmiessler/SecLists ~/tools/SecLists
```

Key wordlist paths for bug bounty recon:
- Subdomains: `~/tools/SecLists/Discovery/DNS/subdomains-top1million-110000.txt`
- API endpoints: `~/tools/SecLists/Discovery/Web-Content/api-endpoints.txt`
- Common files: `~/tools/SecLists/Discovery/Web-Content/common.txt`

## Shodan CLI Setup

```bash
pip install shodan
shodan init YOUR_API_KEY
shodan info  # verify credits
```

Free tier: 1 query credit per search (100 results). Paid membership removes limits and unlocks filters.

Useful Shodan filters for bug bounty:

```bash
# By org name
shodan search 'org:"Target Company"'

# By SSL certificate CN
shodan search 'ssl.cert.subject.cn:"*.example.com"'

# By IP range (from whois)
shodan search 'net:203.0.113.0/24'

# Combine filters
shodan search 'org:"Target Company" http.status:200 http.title:"Admin"'
```

## cloud_enum Configuration

cloud_enum accepts multiple keyword variants. Build a keyword list from:
- Company name (short and full)
- Product names
- Common environment suffixes: `-dev`, `-staging`, `-prod`, `-test`, `-backup`
- Common purpose suffixes: `-assets`, `-data`, `-logs`, `-upload`, `-media`

```bash
cloud_enum \
  -k targetcompany \
  -k "target-company" \
  -k "targetco" \
  --disable-azure   # exclude if Azure clearly not in use (speeds up scan)
```

## subfinder API Keys

subfinder performs significantly better with API keys. Configure in `~/.config/subfinder/provider-config.yaml`:

```yaml
virustotal:
  - YOUR_VT_API_KEY
securitytrails:
  - YOUR_ST_API_KEY
shodan:
  - YOUR_SHODAN_API_KEY
```

Free API keys available from: VirusTotal, SecurityTrails (limited free tier), Shodan.

## Recommended Recon Pipeline

Full passive → active pipeline for a new target:

```bash
TARGET="example.com"
BRAND="examplecompany"

# Passive
subfinder -d $TARGET -silent > subs.txt
curl -s "https://crt.sh/?q=%.$TARGET&output=json" | \
  jq -r '.[].name_value' | sort -u >> subs.txt
sort -u subs.txt -o subs.txt

# Cloud storage
cloud_enum -k $BRAND -k "${BRAND}-dev" -k "${BRAND}-prod" -k "${BRAND}-backup"

# Resolve and fingerprint
cat subs.txt | httpx -silent -status-code -title -tech-detect -cname -o live.txt

# Takeover check
nuclei -l subs.txt -t takeovers/ -silent

# Historical URLs
gau $TARGET | sort -u > historical.txt
```
