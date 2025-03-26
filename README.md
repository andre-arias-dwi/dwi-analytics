GTM for GA4 – Custom Implementation Documentation
This repository documents the custom Google Tag Manager (GTM) setup for GA4 tracking, including custom events, variables, triggers, and data layer usage.

📌 Overview
This GTM container is used to track GA4 data across [website/app name]. It includes enhancements to the base GA4 configuration, such as:

- Custom GA4 event tracking
- JavaScript logic to bridge Adobe Data Layer → GA4
- Reusable custom variables and triggers
- Structured dataLayer.push() implementations

📂 Container Details
- GTM Container ID: GTM-XXXXXXX
- Environment: Production / Staging / Dev (specify as needed)
- GA4 Measurement ID: G-XXXXXXXXXX

🧩 Custom Events
| Event Name | Triggering Action | Parameters Used | Tag Name | Notes |
|---|---|---|---|---|
| adobe_page_view |	Click on "Add to Cart" | button	item_id, item_name, price |	Matches GA4 ecommerce format |

🔧 Custom HTML Tags
Tag Name	Description	Trigger(s)	Script
Tag - Adobe Product Viewed → GA4	Listens for Adobe Data Layer productViewed events and pushes GA4 event	All Pages	adobe-product-viewed.js
Tag - Scroll Depth Logger	Logs scroll events to dataLayer at 25%, 50%, 75%	Scroll Depth Trigger	scroll-depth-logger.js


🧪 Variables
| Variable Name	| Type |	Description |
|---|---|---|
| DLV - ecommerce.items[0].id	| Data Layer Variable |	Gets item ID from ecommerce object |
| JS - Clean URL	JavaScript Variable	Strips query parameters from URL
| CJS - adobeDataLayer.product.Image	Custom JS	Pulls image URL from Adobe Data Layer

🚀 Triggers
Trigger Name	Type	Firing Rules
Add to Cart Click	Click - All Elements	Click classes contain add-to-cart
Scroll 50%	Scroll Depth	Vertical Scroll equals 50%

📤 Data Layer Format
Example dataLayer.push() for ecommerce event:

js
Copy
Edit
dataLayer.push({
  event: "add_to_cart",
  ecommerce: {
    items: [{
      item_id: "123",
      item_name: "Cool Product",
      price: 49.99
    }]
  }
});
🧰 Debugging Tips
Use Preview Mode in GTM for real-time testing.

Use GA Debugger Chrome Extension to verify event payloads.

Check GA4 DebugView to validate real-time event flow.

📒 Notes
GA4 events follow Google's enhanced ecommerce spec.

All variables are prefixed for consistency: DLV -, JS -, CJS -.

Code snippets and data layer formats are included for reference.
