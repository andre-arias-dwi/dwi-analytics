/* eslint-disable */
/* global adobeDataLayer, dataLayer */

//<script>
// Handler function to extract relevant fields from adobeDataLayer's pageView event
function handleAdobePageView(event) {
  if (event && event.event === 'pageView' && event.eventData && event.eventData.user) {
    var user = event.eventData.user;
    var page = event.eventData.page || {};

    // Fallback to empty array if dataLayer isn't initialized
    window.dataLayer = window.dataLayer || [];

    // Push a custom event to GTM's dataLayer to make Adobe data available to GA4
    window.dataLayer.push({
      event: 'adobe_page_view',                     // Custom GA4 event name
      login_status: user.loginType || 'unknown',    // e.g., 'Hard Logged-In', 'Soft Logged-In', 'unidentified'
      user_id: user.customerId || 'unknown',        // Unique customer identifier
      active_state: user.state || 'unknown',        // US state from state selector
      page_name: page.pageName || 'unknown',        // Optional: enriches GA4 page context
      page_type: page.pageType || 'unknown'
    });
  }
}

(function() {
  try {
    // Ensure adobeDataLayer is defined to avoid runtime errors
    window.adobeDataLayer = window.adobeDataLayer || [];

    // Process already-pushed events (important if adobeDataLayer is loaded before this script)
    window.adobeDataLayer.forEach(handleAdobePageView);

    // Monkey-patch adobeDataLayer.push to intercept future pushes
    // Ensures we don't miss pageView events pushed after Initialization
    var originalPush = window.adobeDataLayer.push;
    window.adobeDataLayer.push = function(event) {
      originalPush.call(this, event);
      handleAdobePageView(event);
    };

  } catch (err) {
    // Log any unexpected runtime errors to the console for easier debugging
    console.error('[adobeDataLayer bridge] Error:', err);
  }
})();
//</script>