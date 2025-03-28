# 🔧 Implementation: Adobe → GA4 pageView

**📅 Date Created:** 2025-03-26  (updated on 2025-03-28)
**🆔 GTM Version ID:** 1107  (updated 1113)

**🎯 Purpose:**  
Capture user login state from `adobeDataLayer` and send it to GA4 using a custom event.

**📦 Use Case:**  
`adobeDataLayer` loads after the GA4 config tag fires, so we can’t access user data early in the page lifecycle. This workaround ensures we capture login status and user metadata for segmentation. `dataLayer`  no longer contains this data.

---

## 1. 🧩 Custom HTML Tag

**Tag Name:** `cHTML - pageView – adobeDataLayer → dataLayer`  
**Trigger:** All Pages – Initialization  
**Script:** [`tag_adobe_pageview.js`](./gtm-ga4/tag_adobe_pageview.js) (monkey-patches `adobeDataLayer.push`)

**Description:**

- 🐒 Monkey-patches (intercepts) `adobeDataLayer.push` to handle late pageView events.
- Listens for `pageView` events and extracts user data (`loginType`, `state`, `customerId`)
- Includes fallback mechanisms to ensure the event is captured reliably, even when timing varies between Adobe and GTM:

  - Existing events are processed during Initialization.
  - Polling: In edge cases where Adobe loads after both GTM and getState() return nothing, we check every 100ms for up to 2 seconds (20 tries).
  - `getState()` support: If the Adobe Client Data Layer exposes getState(), we use it to retrieve the most recent pageView object. This is useful when adobeDataLayer.push happened before our code ran (e.g. when loading late in the page).

- Pushes a custom `adobe_page_view` event to GTM's `dataLayer` with the extracted values.
- Includes a `pageViewHandled` flag to **prevent duplicate event pushes** to the `dataLayer`:
  - Adobe may push multiple `pageViews` events for the same page load (confirmed via `console.trace`)
  - Only the first matching `pageView` event is used to trigger the GA4 custom event

---

## 2. 🎯 GA4 Event Tag

**Tag Name:** `GA4 - adobe_page_view`  
**Fires On:** `adobe_page_view` (Custom Event)  
**Parameters:**

`GT - Settings - adobeDataLayer` - can be used in other custom events that depend on adobeDataLayer

| Parameter Name  | Variable Used              | Description |
|------------------|-----------------------------|---|
| `login_status`   | `{{DLV - login_status}}`    | Extracted from `adobe_page_view` |
| `active_state`   | `{{DLV - active_state}}`    | Extracted from `adobe_page_view` |
| `page_fragment`  | `{{CJS - Page URL Fragment}}` | Extracts #fragment from URL (existing) |
| `clp` | `{{JS - CLP}}` | True for closed landing page URLs (existing) |
| `user_id`        | `{{user id}}`         | Returns user ID from `dataLayer` or cookie (existing) |

`{{DLV - user_id}}` created but not used for now, need to understand how it will affect the user id in GA4.

---

### 🛠️ Future Notes

- [ ] Add support for more event types if needed (e.g., product, addToCart)
- [ ] Can be modularized with a centralized handler for multiple Adobe events
- [ ] All user data must now come from `adobeDataLayer` (legacy `dataLayer` is deprecated)
- [ ] Consider adding debug logging for dev environments
