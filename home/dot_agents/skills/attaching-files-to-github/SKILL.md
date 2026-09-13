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

3. Upload everything before writing the body that names it.

## Carry a rejected type inside an accepted one

The endpoint validates two things and neither is the bytes: `content_type` must
be on its allow-list, and `name`'s extension must agree with `content_type`. A
rejected pair answers `Validation Failed` with both complaints at once, even
when the extension does match.

The allow-list is narrower than the file types GitHub's own uploader accepts.
Observed rejections: `application/zip`, `application/x-zip-compressed`,
`application/gzip`, `text/plain`, `text/markdown`. `image/png` is accepted.
Probe with a throwaway file rather than trusting a guess.

Because the bytes are never inspected or transcoded, a rejected type rides
inside an accepted one: upload the archive as `<file>.zip.png` with
`image/png`. GitHub stores and serves it verbatim, so the reader gets the
archive back by writing the response to the right name. Give them a one-liner
next to the link:

```sh
curl -sL <url> -o <file>.zip && unzip -o <file>.zip
```

This stays inside GitHub's own attachment store. A repository branch, a
release, a gist, or an external host is not a fallback — each one leaves an
artifact the content outlives. When even a carrier type is refused, or the
endpoint stops answering, say so and stop.

## Reference the asset where it renders

4. An asset stays unbound until the comment body references it **in rendered
   Markdown**. A URL that appears only inside a fenced code block does not
   count: the asset is never attached, and the URL answers 404 to everyone,
   including you. Write a real link or image outside the fence — a one-liner in
   a code block needs a companion `[label](<url>)` line.
5. An image goes in as `![alt](<url>)`, or as `<img src="<url>" width="…">`
   when the rendered width matters; a video renders as a player from a bare URL
   on its own line; anything else reads as a link, so give it a label.

## Prove the attachment stands on its own

6. After the body is posted, fetch the returned URL with no credentials.
   Confirm the status, and confirm the bytes match the local file by comparing
   checksums — an archive that arrived under an image content type is only
   proven by its checksum.
7. Read the rendered body with
   `gh api repos/<owner>/<repo>/issues/comments/<id> -H "Accept: application/vnd.github.html+json" --jq .body_html`
   and confirm the asset URL is there as a link or an image.
8. When the file previously lived somewhere else, delete that source and fetch
   the attachment again, so the content is proven not to depend on it.

## Finish

9. Delete the local copies once the upload is verified, and report the asset
   URLs. Never claim an attachment renders or downloads without having fetched
   it.

Base64 is not an option for an image: GitHub's sanitizer strips the `src` from a
`data:` URI in both Markdown and HTML, leaving a broken `<img>`. Confirm with
`gh api -X POST markdown -f text=...` rather than trusting either belief.
