"""Linkding MCP server — bridges linkding REST API to MCP stdio transport."""

import json
import os
import sys
from urllib.error import HTTPError, URLError
from urllib.request import Request, urlopen

from mcp.server.fastmcp import FastMCP

base_url = os.environ.get("LINKDING_BASE_URL", "")
api_token = os.environ.get("LINKDING_API_TOKEN", "")

if not base_url:
    print("LINKDING_BASE_URL not set", file=sys.stderr)
    sys.exit(1)
if not api_token:
    print("LINKDING_API_TOKEN not set", file=sys.stderr)
    sys.exit(1)

mcp = FastMCP("linkding")


def _request(method: str, path: str, body: dict | None = None) -> dict | str:
    """Make an authenticated request to the linkding API."""
    url = f"{base_url.rstrip('/')}{path}"
    headers = {
        "Authorization": f"Token {api_token}",
        "Content-Type": "application/json",
    }
    data = json.dumps(body).encode() if body else None
    req = Request(url, data=data, headers=headers, method=method)
    try:
        with urlopen(req) as resp:
            if resp.status == 204:
                return ""
            return json.loads(resp.read())
    except HTTPError as e:
        return {"error": e.code, "detail": e.read().decode()}
    except URLError as e:
        return {"error": "connection_failed", "detail": str(e.reason)}


# ── Bookmarks ────────────────────────────────────────────────────────────────


@mcp.tool()
def search_bookmarks(q: str = "", limit: int = 100, offset: int = 0) -> str:
    """Search bookmarks by query string. Returns matching bookmarks with title, URL, tags, and notes."""
    params = f"?limit={limit}&offset={offset}"
    if q:
        params += f"&q={q}"
    return json.dumps(_request("GET", f"/api/bookmarks/{params}"), indent=2)


@mcp.tool()
def get_bookmark(id: int) -> str:
    """Get a single bookmark by ID."""
    return json.dumps(_request("GET", f"/api/bookmarks/{id}/"), indent=2)


@mcp.tool()
def create_bookmark(
    url: str,
    title: str = "",
    description: str = "",
    notes: str = "",
    tag_names: list[str] | None = None,
    is_archived: bool = False,
    unread: bool = False,
    shared: bool = False,
) -> str:
    """Create a new bookmark."""
    body: dict = {"url": url}
    if title:
        body["title"] = title
    if description:
        body["description"] = description
    if notes:
        body["notes"] = notes
    if tag_names:
        body["tag_names"] = tag_names
    if is_archived:
        body["is_archived"] = is_archived
    if unread:
        body["unread"] = unread
    if shared:
        body["shared"] = shared
    return json.dumps(_request("POST", "/api/bookmarks/", body), indent=2)


@mcp.tool()
def update_bookmark(
    id: int,
    url: str = "",
    title: str = "",
    description: str = "",
    notes: str = "",
    tag_names: list[str] | None = None,
) -> str:
    """Partially update a bookmark. Only provided fields are changed."""
    body: dict = {}
    if url:
        body["url"] = url
    if title:
        body["title"] = title
    if description:
        body["description"] = description
    if notes:
        body["notes"] = notes
    if tag_names is not None:
        body["tag_names"] = tag_names
    return json.dumps(_request("PATCH", f"/api/bookmarks/{id}/", body), indent=2)


@mcp.tool()
def delete_bookmark(id: int) -> str:
    """Delete a bookmark by ID."""
    result = _request("DELETE", f"/api/bookmarks/{id}/")
    return "Bookmark deleted" if result == "" else json.dumps(result, indent=2)


@mcp.tool()
def archive_bookmark(id: int) -> str:
    """Archive a bookmark."""
    result = _request("POST", f"/api/bookmarks/{id}/archive/")
    return "Bookmark archived" if result == "" else json.dumps(result, indent=2)


@mcp.tool()
def unarchive_bookmark(id: int) -> str:
    """Unarchive a bookmark."""
    result = _request("POST", f"/api/bookmarks/{id}/unarchive/")
    return "Bookmark unarchived" if result == "" else json.dumps(result, indent=2)


@mcp.tool()
def list_archived_bookmarks(q: str = "", limit: int = 100, offset: int = 0) -> str:
    """List archived bookmarks, optionally filtered by query."""
    params = f"?limit={limit}&offset={offset}"
    if q:
        params += f"&q={q}"
    return json.dumps(_request("GET", f"/api/bookmarks/archived/{params}"), indent=2)


@mcp.tool()
def check_url(url: str) -> str:
    """Check if a URL is already bookmarked and get scraped metadata."""
    return json.dumps(_request("GET", f"/api/bookmarks/check/?url={url}"), indent=2)


# ── Tags ─────────────────────────────────────────────────────────────────────


@mcp.tool()
def list_tags(limit: int = 100, offset: int = 0) -> str:
    """List all tags with usage counts."""
    return json.dumps(
        _request("GET", f"/api/tags/?limit={limit}&offset={offset}"), indent=2
    )


@mcp.tool()
def get_tag(id: int) -> str:
    """Get a single tag by ID."""
    return json.dumps(_request("GET", f"/api/tags/{id}/"), indent=2)


@mcp.tool()
def create_tag(name: str) -> str:
    """Create a new tag."""
    return json.dumps(_request("POST", "/api/tags/", {"name": name}), indent=2)


# ── Bundles ──────────────────────────────────────────────────────────────────


@mcp.tool()
def list_bundles(limit: int = 100, offset: int = 0) -> str:
    """List all bundles."""
    return json.dumps(
        _request("GET", f"/api/bundles/?limit={limit}&offset={offset}"), indent=2
    )


@mcp.tool()
def get_bundle(id: int) -> str:
    """Get a single bundle by ID."""
    return json.dumps(_request("GET", f"/api/bundles/{id}/"), indent=2)


@mcp.tool()
def create_bundle(
    name: str, description: str = "", filter_query: str = ""
) -> str:
    """Create a new bundle with an optional filter query."""
    body: dict = {"name": name}
    if description:
        body["description"] = description
    if filter_query:
        body["filter_query"] = filter_query
    return json.dumps(_request("POST", "/api/bundles/", body), indent=2)


@mcp.tool()
def update_bundle(
    id: int, name: str = "", description: str = "", filter_query: str = ""
) -> str:
    """Partially update a bundle."""
    body: dict = {}
    if name:
        body["name"] = name
    if description:
        body["description"] = description
    if filter_query:
        body["filter_query"] = filter_query
    return json.dumps(_request("PATCH", f"/api/bundles/{id}/", body), indent=2)


@mcp.tool()
def delete_bundle(id: int) -> str:
    """Delete a bundle by ID."""
    result = _request("DELETE", f"/api/bundles/{id}/")
    return "Bundle deleted" if result == "" else json.dumps(result, indent=2)


# ── User ─────────────────────────────────────────────────────────────────────


@mcp.tool()
def get_user_profile() -> str:
    """Get the current user's profile settings."""
    return json.dumps(_request("GET", "/api/user/profile/"), indent=2)


if __name__ == "__main__":
    mcp.run(transport="stdio")
