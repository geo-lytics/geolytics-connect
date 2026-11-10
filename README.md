# Geolytics Connect

Geolytics Connect describes the two ways to access Geolytics content programmatically:

| | **REST API** | **MCP Server** |
|---|---|---|
| **Best for** | IT teams: bulk export into internal systems, archives, data pipelines | Analysts and AI assistants (Claude and other MCP clients): ask questions in natural language |
| **Authentication** | API key (provided by Geolytics) | OAuth 2.0 login with your Geolytics Hub account |
| **Content** | Analyses (full text + metadata) | Analyses **plus** client-specific implications, political calendar, economic dashboards, policy database |
| **Output** | JSON, converted to Markdown by the included Python script | Structured results inside your AI assistant |
| **Docs** | [Section 1–3](#1-rest-api-overview) | [Section 4](#4-mcp-server) |

Both interfaces are read-only and only return content covered by your organization's subscription.

---

## 1. REST API Overview

The REST API allows clients to bulk download the latest analysis along with their associated metadata, including last edited time, authors, channels, tags, countries, and key takeaways.

The primary target users are clients' IT teams, who can:
- Retrieve report lists and detailed content;
- Convert the downloaded JSON content into Markdown files using the provided Python converter, making it easy to store, archive, and display in internal systems.

### Update Cycle
- All analysis and research are finalized by Friday each week.
- The latest reports become available through the API after Friday EOB (18:00 Central European Time, CET/CEST).
- Clients can fetch the complete set of new reports after this time.

### API Features
- Standardized JSON interface: all responses follow a unified JSON format (and then converted to Markdown by Python);
- Basic pagination support: by default, 5 records are returned per request, with paging supported via the offset parameter;
- Secure access: API Key.

## 2. REST API: How To Use

### 2.1 Installation

(1) Clone or download this repository to your local machine
```bash
git clone https://github.com/geo-lytics/geolytics-connect.git
cd geolytics-connect
```

(2) Install Python dependencies: (Python: 3.6 or higher)

```bash
pip install -r requirements.txt
```

(3) Configure API settings:

```bash
# Copy the example config file
cp config.example.py config.py
```

Create a file named `.env` in the project folder with the following content (the API key is provided separately):

```
API_BASE_URL=https://zlegl6sgdl.execute-api.eu-central-1.amazonaws.com/prod
API_KEY=your-api-key-here
```

Both the Python script and `fetch_raw.ps1` read these values from `.env`. Environment variables with the same names (`API_KEY`, `API_BASE_URL`) take precedence over `.env`. If `API_BASE_URL` is omitted, the URL above is used. Keep `.env` private; it is excluded from git by `.gitignore`.

### 2.2 Quick Start

```bash
python download_and_convert.py
```

By default, the script retrieves the latest 10 articles, fetching 5 at a time in accordance with the API limit. This volume is sufficient to cover all weekly updates now and daily updates in the future.

All exported articles can be found in the md_export folder.

An operation log is maintained in the log.md file, which automatically tracks newly added or updated article headlines. Please refer to the sections below for more details.

**Other options:**
- `--batch-size`: Articles per batch, default 5
- `--num-batches`: Number of batches to download, default 2
- `--skip-download`: Skip download and only convert from json, default False

**Example:**
```bash
python download_and_convert.py --batch-size 2 --num-batches 1
python download_and_convert.py --skip-download
```

**Raw JSON only (PowerShell, no Python required):**

`fetch_raw.ps1` calls the API once and saves the unprocessed JSON response, which is useful for testing the connection or integrating the JSON directly into your own systems. It reads `API_BASE_URL` and `API_KEY` from `.env` like the Python script.

```powershell
.\fetch_raw.ps1                          # latest 5 articles -> raw.json
.\fetch_raw.ps1 -Limit 2 -Offset 5       # 2 articles, skipping the first 5
.\fetch_raw.ps1 -OutFile latest.json     # save to a different file
```

Parameters: `-Limit` (1–5, default 5), `-Offset` (default 0), `-OutFile` (default `raw.json`). `-ApiKey` and `-BaseUrl` can also be passed explicitly to override `.env`. If the request fails, the output file is left unchanged.

If PowerShell blocks the script with an execution policy error, run it with:

```powershell
powershell -ExecutionPolicy Bypass -File .\fetch_raw.ps1
```

### 2.3 Output Files

Only new or changed articles trigger file updates.

**(1) Individual Article Files (in the md_export folder):**

Each article is saved as a Markdown file with the format: `{id}-{title}.md`

**(2) Log File (log.md):**

Complete operation history with timestamps and statistics.

### 2.4 File Structure

```
project/
├── download_and_convert.py     # Main script
├── config.py                   # API configuration (create from config.example.py)
├── config.example.py           # Example configuration file
├── .env                        # Your API key (create yourself, never commit)
├── fetch_raw.ps1               # Optional: fetch raw JSON with PowerShell only
├── requirements.txt            # Python dependencies
├── README.md                   # Documentation
├── log.md                      # Operation log (created automatically)
├── raw.json                    # Downloaded API data (created automatically)
└── md_export/                  # Output directory
    └── *.md                    # Individual article files
```

### 2.5 Weekly Automation

Since new analysis and reports are finalized every Friday and made available via the API after Friday EOB (18:00 CET/CEST), we recommend scheduling the script to run once per week after this time.

**Windows Task Scheduler:**
- Open Task Scheduler (taskschd.msc)
- Create Basic Task
- Set trigger to Weekly, choose Friday at e.g. 19:00 CET/CEST
- Set action to start program: python
- Add arguments: download_and_convert.py
- Set "Start in" directory to your project folder

**Linux/Mac Cron:**
Add the following to your crontab to run every Friday at 19:00:
```bash
0 19 * * FRI cd /path/to/project && python download_and_convert.py
```

## 3. REST API Reference

### 3.1 API Parameters

**Endpoint:**
```
GET /v1/topics/export
```

**Header:**
```
x-api-key: <your API key>
```

**Query Parameters:**
- `limit` (integer, optional):
  Maximum number of topics to return. Default and maximum value: 5.

- `offset` (integer, optional):
  Number of topics to skip before starting to return results. Default: 0.

### 3.2 API Setup & Security

- **Authentication**: Access is secured with an API key in the HTTP headers. Each client receives a unique key for tracking and access control.

- **IP Whitelisting**: Not enabled by default. This can be configured upon request to restrict API access to specific server IPs.

- **Encryption**: All traffic is served over HTTPS (TLS 1.2+), ensuring that data in transit is fully encrypted.

- **Data Access**: The API is strictly read-only. No write or modification operations are supported.

### 3.3 Rate Limits & Quotas

- **Rate limit**: 1 request per second, with a short burst allowance of 2 requests.

- **Quota**: 5 requests per week (temporarily adjusted to 20 per day for testing purposes).

- **Exceeding limits**: Requests over the quota or rate limit will return an error response.

---

## 4. MCP Server

The Geolytics Hub MCP server lets AI assistants that support the [Model Context Protocol](https://modelcontextprotocol.io) (such as Claude) search and read Geolytics content directly. Instead of exporting files, you ask questions like *"What did Geolytics write about EU export controls this month, and what are the implications for us?"* and the assistant calls the right tools.

Compared with the REST API, the MCP server offers more content: besides analyses, it gives access to the implications prepared for your organization, the political calendar, the economic dashboards and the policy database.

### 4.1 Connection Details

| Setting | Value |
|---|---|
| **Server URL** | `https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/mcp` |
| **Transport** | Streamable HTTP |
| **Authentication** | OAuth 2.0 (authorization code + PKCE). Log in with your **Geolytics Hub** account. |

No API key or client secret is needed. The MCP client discovers the login page automatically from the server URL.

### 4.2 Connect from Claude (web and desktop app)

1. Open **Settings → Connectors** and click **Add custom connector**.
   On Team and Enterprise plans, an organization owner may need to add the connector first.
2. Enter a name (e.g. `Geolytics Hub`) and the server URL:
   ```
   https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/mcp
   ```
3. Click **Connect**. A Geolytics Hub login page opens in your browser.
4. Log in with your Geolytics Hub email and password. After a successful login you are redirected back and the connector shows as connected.
5. In a chat, enable the connector from the tools menu and ask your question.

### 4.3 Connect from Claude Code

```bash
claude mcp add --transport http geolytics-hub https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/mcp
```

Then start Claude Code, run `/mcp`, select `geolytics-hub` and choose **Authenticate**. Log in with your Geolytics Hub account in the browser window that opens.

### 4.4 Other MCP Clients

Any MCP client that supports **Streamable HTTP** and **OAuth 2.0 authorization** for remote servers can connect using the server URL above. The server publishes standard discovery metadata, so compatible clients configure the login automatically:

| Metadata | URL |
|---|---|
| Protected resource metadata | `https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/.well-known/oauth-protected-resource` |
| Authorization server metadata | `https://haxl39qde5.execute-api.eu-central-1.amazonaws.com/.well-known/oauth-authorization-server` |

Supported: authorization code flow with PKCE (`S256`), refresh tokens, dynamic client registration and client ID metadata documents. Scopes: `openid email profile`.

### 4.5 How Login Works

1. The MCP client calls the server without a token and receives `401 Unauthorized` with a pointer to the OAuth metadata.
2. The client opens the Geolytics Hub login page in your browser.
3. You log in with your Geolytics Hub account (the same credentials you use on [hub.geo-lytics.com](https://hub.geo-lytics.com)).
4. The client receives an access token, sends it with every request, and refreshes it automatically.

Your Hub account determines which content you can see: results are limited to the channels your organization subscribes to, and implications are only those released to your organization.

### 4.6 Available Tools

**Analyses**

| Tool | Description |
|---|---|
| `list_subscribed_channels` | Lists the channels your organization is subscribed to. |
| `get_topics` | Lists analyses, newest first or ranked by keyword relevance. Filters: `channel_id`, `keyword`, `date_from`, `date_to`, `limit` (max 100), `offset`. |
| `get_topic_detail` | Full content of one analysis by its ID, including **implications for your organization** where available. |
| `search_topic_passages` | Keyword search across sections of all accessible analyses. Returns the best-matching passages with links. Filters: `query`, `top_k`, `per_topic_max_passages`, `channel_id`, `date_from`, `date_to`. |
| `get_topic_related_context` | Political events and related analyses linked to one analysis. |

**Political Calendar**

| Tool | Description |
|---|---|
| `get_political_calendar_events` | Upcoming and past political events. Filters: `month` (YYYY-MM), `q`, `date_from`, `date_to`, `region`, `type`, `sector`, `industry`, `tbd`, `limit`, `offset`. Events relevant to your organization are highlighted. |
| `get_political_calendar_event_detail` | One event with its linked analyses, tags and channels. |

**Economic Dashboards**

| Tool | Description |
|---|---|
| `get_economic_macro_snapshot` | Latest macro indicators with historical percentile ranking and comparison with the previous month and the prior-year average. |
| `get_economic_macro_history` | Full monthly history of one macro indicator (`indicator_en`). |
| `get_economic_macro_categories` | Latest commentary for each macro category. |
| `get_economic_industry_snapshot` | Industry indicators for a given month (`YYYYMM`) or the latest month. |
| `get_economic_industry_history` | Up to four years of monthly history for industry indicators. |

**Policy Database**

| Tool | Description |
|---|---|
| `get_policy_database_entries` | Policy documents with filters on `source`, `subcategory`, `date_from`, `date_to`, `q`, `limit`, `offset`. |

### 4.7 Example Questions

- *"Summarize this week's Geolytics analyses and list the implications for our company."*
- *"Which political events in the next two months could affect the automotive sector?"*
- *"How has China's industrial value-add developed over the last year? Show the latest macro snapshot."*
- *"Find everything Geolytics wrote about export controls on semiconductors since January."*

### 4.8 Troubleshooting

| Problem | Solution |
|---|---|
| Login page does not open | Make sure your browser allows pop-ups from your AI client, then reconnect. |
| `401 Unauthorized` after login | Disconnect and reconnect the connector to obtain a new token. |
| `Missing or invalid custom:client_id in access token` | Your Hub account is not yet linked to your organization. Please contact Geolytics. |
| A topic is "not found or not accessible" | The analysis belongs to a channel your organization does not subscribe to. |
