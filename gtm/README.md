# GTM Custom Implementations

> Internal documentation for non-standard GA4 setups that rely on adobeDataLayer or other advanced logic.

---

## Adobe Data Layer Bridges

- [Adobe Data Layer Click Events – GTM → GA4](./docs/adobe_custom_click_events_bridge.md)
  Pushes `adobeDataLayer` custom events to `dataLayer` (Google Tag Manager)

- [Adobe → GA4: pageView](./docs/adobe_pageview_bridge.md)
  Captures login status from adobeDataLayer and pushes it to GA4 via the custom event `adobe_page_view`
