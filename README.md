# Geolytics Connect

Connect Geolytics analysis and data to your own AI platform or internal systems in minutes.

- **MCP Server**: plug Geolytics into any AI assistant or agent platform that supports the [Model Context Protocol](https://modelcontextprotocol.io). Users ask questions in natural language; the AI retrieves analyses, implications for your organization, the political calendar, economic dashboards and the policy database.
- **REST API**: bulk export of analyses as JSON or Markdown for archives, intranets and data pipelines (analyses only).

Both are read-only, encrypted (HTTPS) and limited to your organization's subscription.

## Quick Start

### MCP: connect your AI platform

1. In your AI platform, add a remote MCP server with this URL:
   ```
   https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/mcp
   ```
2. Log in with your **Geolytics Hub** account when the login page opens.
3. Ask a question, e.g. *"What are this week's Geolytics analyses and their implications for us?"*

### REST API: export analyses to Markdown

```bash
git clone https://github.com/geo-lytics/geolytics-connect.git
cd geolytics-connect
pip install -r requirements.txt
cp config.example.py config.py
echo "API_KEY=your-api-key-here" > .env    # API key is provided by Geolytics
python download_and_convert.py
```

The latest analyses are saved as Markdown files in `md_export/`.

---

## 1. MCP Server

### Connection

| | |
|---|---|
| Server URL | `https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/mcp` |
| Transport | Streamable HTTP |
| Authentication | OAuth 2.0 authorization code + PKCE, login with Geolytics Hub account |

Any MCP client with remote server and OAuth support can connect. No API key or client secret is required: the client discovers the login flow from standard metadata.

**For platform administrators:**

| | |
|---|---|
| Protected resource metadata | `https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/.well-known/oauth-protected-resource` |
| Authorization server metadata | `https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/.well-known/oauth-authorization-server` |
| Supported | PKCE (`S256`), refresh tokens, dynamic client registration, client ID metadata documents |
| Scopes | `openid email profile` |

Each user's Hub account determines what they can see: content from your organization's subscribed channels and implications released to your organization.

### Tools

| Area | Tool | Description |
|---|---|---|
| Analyses | `list_subscribed_channels` | Channels your organization subscribes to |
| | `get_topics` | List or keyword-search analyses, filter by channel and date |
| | `get_topic_detail` | Full analysis, including **implications for your organization** |
| | `search_topic_passages` | Keyword search across sections of all analyses |
| | `get_topic_related_context` | Political events and analyses linked to an analysis |
| Political calendar | `get_political_calendar_events` | Events filtered by month, region, type, sector, industry or keyword |
| | `get_political_calendar_event_detail` | One event with linked analyses |
| Economic dashboards | `get_economic_macro_snapshot` | Latest macro indicators vs. history, previous month and prior year |
| | `get_economic_macro_history` | Monthly history of one macro indicator |
| | `get_economic_macro_categories` | Latest commentary per macro category |
| | `get_economic_industry_snapshot` | Industry indicators for a given or the latest month |
| | `get_economic_industry_history` | Up to four years of industry indicator history |
| Policy database | `get_policy_database_entries` | Policy documents filtered by source, category, date or keyword |

### Troubleshooting

| Problem | Solution |
|---|---|
| `401 Unauthorized` | Reconnect the server to log in again. |
| `Missing or invalid custom:client_id` | Your Hub account is not yet linked to your organization. Please contact Geolytics. |
| Topic "not found or not accessible" | It belongs to a channel outside your subscription. |

---

## 2. REST API

New analyses are published every Friday and available via the API after 18:00 CET/CEST.

### Configuration

Create `.env` in the project folder:

```
API_KEY=your-api-key-here
API_BASE_URL=https://zlegl6sgdl.execute-api.eu-central-1.amazonaws.com/prod
```

`API_BASE_URL` is optional (the value above is the default). Environment variables with the same names override `.env`. Keep `.env` private; it is excluded from git.

### Usage

```bash
python download_and_convert.py                                # latest 10 analyses
python download_and_convert.py --batch-size 2 --num-batches 1 # latest 2
python download_and_convert.py --skip-download                # re-convert existing raw.json
```

- `md_export/{id}-{title}.md`: one Markdown file per analysis, only rewritten when new or changed
- `log.md`: history of added and updated analyses
- `raw.json`: last API response

**PowerShell only (no Python):** save the raw JSON response, using the same `.env`:

```powershell
.\fetch_raw.ps1                       # latest 5 -> raw.json
.\fetch_raw.ps1 -Limit 2 -Offset 5 -OutFile latest.json
```

If blocked by the execution policy: `powershell -ExecutionPolicy Bypass -File .\fetch_raw.ps1`

### Weekly Automation

Schedule `python download_and_convert.py` every Friday after 19:00 CET/CEST, e.g. with Windows Task Scheduler (set "Start in" to the project folder) or cron:

```bash
0 19 * * FRI cd /path/to/geolytics-connect && python download_and_convert.py
```

### Reference

```
GET {API_BASE_URL}/v1/topics/export?limit=5&offset=0
x-api-key: <your API key>
```

| Parameter | Description |
|---|---|
| `limit` | Number of analyses, 1–5 (default 5) |
| `offset` | Number of analyses to skip (default 0) |

Each analysis includes title, authors, publisher, last edited date, channels, tags, countries, key takeaways and full content.

- **Security**: HTTPS (TLS 1.2+), one API key per client, read-only. IP whitelisting available on request.
- **Rate limit**: Requests are subject to rate limits and quotas. Requests over the limit return an error.
