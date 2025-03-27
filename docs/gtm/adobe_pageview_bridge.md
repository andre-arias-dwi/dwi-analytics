# 🔧 Implementation: Adobe → GA4 pageView

**📅 Date Created:** 2025-03-26  
**🆔 GTM Version ID:** 1107  

**🎯 Purpose:**  
Capture user login state from `adobeDataLayer` and send it to GA4 using a custom event.

**📦 Use Case:**  
`adobeDataLayer` loads after the GA4 config tag fires, so we can’t access user data early in the page lifecycle. This workaround ensures we capture login status for segmentation. `dataLayer` does not contain these values anymore.

---

## 1. 🧩 Custom HTML Tag

**Tag Name:** `cHTML - pageView – adobeDataLayer → dataLayer`  
**Trigger:** All Pages – Initialization  
**Script:** [`tag_adobe_pageview.js`](./gtm-ga4/tag_adobe_pageview.js) (monkey-patches `adobeDataLayer.push`)

**Description:**

- 🐒 Monkey-patches (intercepts) `adobeDataLayer.push`
- Listens for `pageView` events and extracts user data (`loginType`, `state`, `customerId`)
- Pushes an `adobe_page_view` event to GTM's `dataLayer`
- Enables GA4 tracking when `adobeDataLayer` loads after Initialization
- Includes a `pageViewHandled` flag to **prevent duplicate event pushes**
  - Adobe sometimes pushes multiple `pageViews` objects per page load (confirmed via `console.trace`)
  - Only the first `pageView` event is used to rigger the GA4 custom event

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
