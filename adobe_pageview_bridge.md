## 🔧 Implementation: Adobe → GA4 pageView

**📅 Date Created:** 2025-03-26  
**🆔 GTM Version ID:** 1107  

**🎯 Purpose:**  
Capture user login state from `adobeDataLayer` and send it to GA4.

**📦 Use Case:**  
`adobeDataLayer` loads after the GA4 config tag fires, so we can’t access user data early in the page lifecycle. This workaround ensures we capture login status for segmentation.

---

### 1. 🧩 Custom HTML Tag

**Tag Name:** `cHTML - pageView – adobeDataLayer → dataLayer`  
**Trigger:** All Pages – Initialization  
**Script:** [`tag_adobe_pageview.js`](./gtm-ga4/tag_adobe_pageview.js) (monkey-patches `adobeDataLayer.push`)

**Description:**
- 🐒 Monkey-patches (intercepts) `adobeDataLayer.push`
- Listens for `pageView` events and extracts user data (`loginType`, `state`, `customerId`)
- Pushes an `adobe_page_view` event to GTM's `dataLayer`
- Enables GA4 tracking when `adobeDataLayer` loads after Initialization

---

### 2. 🎯 GA4 Event Tag

**Tag Name:** `GA4 - adobe_page_view`  
**Fires On:** `adobe_page_view` (Custom Event)  
**Parameters:**

| Parameter Name  | Variable Used              |
|------------------|-----------------------------|
| `login_status`   | `{{DLV - login_status}}`    |
| `user_id`        | `{{DLV - user_id}}`         |
| `active_state`   | `{{DLV - active_state}}`    |

---

### 🛠️ Future Notes

- [ ] Add support for more event types if needed (e.g., product, addToCart)
- [ ] Can be modularized with a centralized handler for multiple Adobe events
- [ ] All user data must now come from `adobeDataLayer` (legacy `dataLayer` is deprecated)
- [ ] Consider adding debug logging for dev environments
