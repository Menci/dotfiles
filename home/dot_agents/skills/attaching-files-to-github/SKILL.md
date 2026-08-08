---
name: attaching-files-to-github
description: Use when a file belongs in a GitHub Issue, Pull Request, or comment
  — a screenshot, a recording, a log, an archive. Uploads it as a real
  attachment with the token `gh` already holds. Never parks a file in a
  repository branch, a release, a gist, or an external host; never asks the
  human to drag and drop.
---

# Attaching Files to GitHub Content

Puts a file into GitHub content the way a drag-and-drop does, leaving nothing
behind anywhere else.

## Upload before writing the body

1. Read the repository id with `gh api repos/<owner>/<repo> --jq .id`.
2. Post the file to the attachment endpoint. It is undocumented but accepts the
   same bearer token `gh` holds, and answers with the canonical asset URL:

   ```bash
   curl -s -X POST \
     "https://uploads.github.com/user-attachments/assets?name=<file>&content_type=<mime>&repository_id=<id>" \
     -H "Authorization: Bearer $(gh auth token)" \
     -H "Accept: application/json" \
     --data-binary "@<file>"
   # → {"url":"https://github.com/user-attachments/assets/<uuid>"}
   ```

3. Match `content_type` to the file, and upload everything before writing the
   body that names it. An image goes in as `![alt](<url>)`, or as
   `<img src="<url>" width="…">` when the rendered width matters; a video
   renders as a player from a bare URL on its own line; anything else reads as
   a link, so give it a label: `[<label>](<url>)`.
4. GitHub accepts a fixed set of file types. When the endpoint rejects one, or
   stops answering, say so and stop. A repository branch, a release, or an
   external host is not a fallback — each one leaves an artifact the content
   outlives.

## Prove the attachment stands on its own

5. Fetch the returned URL with no credentials. Confirm the status, the content
   type, and that the bytes match the local file.
6. Read the rendered body with
   `gh api repos/<owner>/<repo>/issues/comments/<id> -H "Accept: application/vnd.github.html+json" --jq .body_html`.
   A real attachment resolves to `private-user-images.githubusercontent.com`
   carrying a JWT; a proxied external link does not.
7. When the file previously lived somewhere else, delete that source and fetch
   the attachment again, so the content is proven not to depend on it.

## Finish

8. Delete the local copies once the upload is verified, and report the asset
   URLs. Never claim an attachment renders without having fetched it.

Base64 is not an option for an image: GitHub's sanitizer strips the `src` from a
`data:` URI in both Markdown and HTML, leaving a broken `<img>`. Confirm with
`gh api -X POST markdown -f text=...` rather than trusting either belief.
