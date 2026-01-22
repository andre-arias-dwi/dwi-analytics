# Adobe Data Layer Click Events – GTM → GA4 Documentation

## Overview

This implementation captures click events emitted by the Adobe Client Data Layer (ACDL), forwards them into Google Tag Manager (GTM) via a bridge, and sends normalized events to GA4.

The design separates responsibilities clearly:

- Adobe Data Layer emits structured click events
- GTM bridge listens and forwards approved events
- GTM configuration normalizes event names and sends them to GA4

---

## High-level flow

1. A user interaction triggers an ACDL event (for example homepage or main navigation click)
2. The bridge listens for Adobe Data Layer events using `addEventListener`
3. Approved events are pushed into GTM’s `dataLayer` as custom events (`acdl.<eventName>`)
4. A GA4 Event tag fires and sends a normalized GA4 event with shared parameters

---

## GTM components

### 1. ACDL → GTM Bridge (Custom HTML tag)
GTM Tag Name: cHTML - adobeDataLayer events - dataLayer push
[`tag_adobe_custom_click_events_bridge.js`](./gtm-ga4/tag_adobe_custom_click_events_bridge.js)

**Purpose**  
Listens for Adobe Client Data Layer events and forwards approved events into GTM.

**Key behavior**

- Uses `addEventListener('adobeDataLayer:event', …)` to listen for events as they occur  
- Ensures events are captured reliably regardless of script load timing  
- Filters events using an internal allowlist (for example homepage and main navigation events)  
- Pushes a GTM-compatible event into `dataLayer`:
  - `event`: `acdl.<eventName>`
  - `acdlEventName`: original Adobe event name
  - `acdl`: full original Adobe event payload

**Why `addEventListener` is used**

- Adobe Data Layer emits events asynchronously
- Listening to events is more reliable than reading state
- Avoids timing issues, polling, or fragile object inspection

---

### 2. GA4 Event Name Mapping (RegEx Table variable)

**Purpose**  
Normalizes Adobe Data Layer events into a small, consistent set of GA4 event names.

**How it works**

- Input: GTM `{{Event}}` (for example `acdl.homeHeroBanner`)
- RegEx rules map event families to GA4 events:
  - `^acdl\.home.*` → `homepage_click`
  - `^acdl\.mainNavClick$` → `main_navigation`
- A default value is used as a fallback for unmapped events

**Why this approach**

- Single source of truth for event name normalization
- Easy to extend without touching triggers or tags
- Flexible enough for current event volume

---

### 3. GA4 Event Tag

**Purpose**  
Sends click events to GA4 with consistent naming and parameters.

**Trigger**

- Fires on bridged ACDL events pushed by the bridge

**Event name**

- Sourced from the RegEx Table mapping variable

**Parameters sent**

- Event category and subcategory (parsed from click description)
- Click text
- Click URL (Adobe value with GTM fallback)

This keeps GA4 reporting consistent across all sites and click types.

---

## Adobe Data Layer event requirements

For an event to be captured and reported correctly, the ACDL payload should include:

- `event` (string, for example `homeHeroBanner`, `mainNavClick`)
- `eventData.click.clickDescription` (colon-delimited string)
- Optional: `eventData.click.clickUrl`

The bridge forwards the full payload unchanged.

---

## Adding new events

- If a new Adobe event matches an existing RegEx rule, no GTM changes are required
- If a new event needs its own GA4 mapping, add a row to the RegEx Table
- No trigger or tag updates are needed

---

## Future enhancement (config-driven bridge)

As event volume or complexity increases, this setup can be upgraded to a config-driven bridge.

In that model:

- A single config object inside the bridge controls:
  - allowed Adobe events
  - GA4 event name mapping
- The bridge pushes a normalized GTM event with the final GA4 event name already resolved
- GTM lookup tables and event-specific triggers are no longer required

This would centralize all logic in one place, but is not necessary given current scale.
