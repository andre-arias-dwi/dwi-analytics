/* eslint-disable */
/* global adobeDataLayer, dataLayer */

// NOT USED - adobeDataLayer was loading too late in the page lifecycle
// Custom JavaScript Variable for GTM
// Purpose: Extract the user's login status from adobeDataLayer (loginType)
// Used as a GA4 event parameter: 'login_status'
// GTM Variable Name: {{CJS - adobeDataLayer - loginType}} Laithwaites
function loginStatus() {
    try {
      var events = window.adobeDataLayer || [];

    // Loop through the adobeDataLayer to find the first 'pageView' event
      for (var i = 0; i < events.length; i++) { 
        var e = events[i];

        // Check if e exists, is a pageView, and has the right nested structure
      if (
        e &&
        e.event === "pageView" &&
        e.eventData &&
        e.eventData.user &&
        typeof e.eventData.user.loginType !== "undefined"
        ) {
          return e.eventData.user.loginType;
        }
      }
  
      return "unknown"; // Fallback if loginStatus is not found in any pageView event
    } catch (e) {
      return "unknown"; // Fallback in case of any runtime error
    }
  }

