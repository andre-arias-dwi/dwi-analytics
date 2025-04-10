/* eslint-disable */
/* global adobeDataLayer, dataLayer */

//<script>

// Flag to ensure the pageView is only handled once per page load.

var pageViewHandled = false;


 // Handles adobeDataLayer `pageView` event by pushing a new event into GTM's dataLayer.
 // Extracts user and page details to pass along to GA4.

function handleAdobePageView(event) {
  if (
    pageViewHandled ||
    !event ||
    event.event !== 'pageView' ||
    !event.eventData ||
    !event.eventData.user
  ) {
    console.warn('[Bridge] pageView conditions not met or already handled:', event);
    return;
  }

  pageViewHandled = true;

  var user = event.eventData.user;
  var page = event.eventData.page || {};

  window.dataLayer = window.dataLayer || [];

  // Temporary log for debugging during rollout
  console.log('[Bridge] Pushing adobe_page_view to dataLayer:', {
    login_status: user.loginType,
    user_id: user.customerId,
    state: user.state
  });

  window.dataLayer.push({
    event: 'adobe_page_view',
    login_status: user.loginType || 'unknown',
    user_id: user.customerId || 'unknown',
    active_state: user.state || 'unknown',
    page_name: page.pageName || 'unknown',
    page_type: page.pageType || 'unknown'
  });
}


 // Fallback polling in case adobeDataLayer events are delayed.
 // Polls for the first pageView event if it hasn’t been processed yet.
 
var adlPollAttempts = 0;
var adlMaxAttempts = 20;
function adlFallbackPoll() {
  if (
    !pageViewHandled &&
    window.adobeDataLayer &&
    window.adobeDataLayer[0] &&
    window.adobeDataLayer[0].event === 'pageView' &&
    window.adobeDataLayer[0].eventData &&
    window.adobeDataLayer[0].eventData.user
  ) {
    console.log('[Bridge] Fallback: found pageView during polling');
    handleAdobePageView(window.adobeDataLayer[0]);
  } else if (!pageViewHandled && adlPollAttempts < adlMaxAttempts) {
    adlPollAttempts++;
    setTimeout(adlFallbackPoll, 100);
  }
}

/**
 * Initializes the adobeDataLayer bridge by:
 * - Processing any pre-existing events
 * - Monkey-patching push()
 * - Attempting fallback via getState()
 * - Starting polling as a final fallback
 */
(function () {
  try {
    window.adobeDataLayer = window.adobeDataLayer || [];

    console.log('[Bridge] adobeDataLayer length on load:', window.adobeDataLayer.length);
    console.log('[Bridge] Patching adobeDataLayer.push');

    // Process any pre-existing adobeDataLayer events
    for (var i = 0; i < window.adobeDataLayer.length; i++) {
      handleAdobePageView(window.adobeDataLayer[i]);
    }

    // Intercept future pushes
    var originalPush = window.adobeDataLayer.push;
    window.adobeDataLayer.push = function (event) {
      originalPush.call(this, event);
      handleAdobePageView(event);
    };

    // Try to use getState() if available
    if (typeof window.adobeDataLayer.getState === 'function') {
      var state = window.adobeDataLayer.getState();
      if (state && state.eventData && state.eventData.user) {
        console.log('[Bridge] Fallback: getState() returned user data');
        handleAdobePageView({
          event: 'pageView',
          eventData: state.eventData
        });
      }
    }

    // Start polling as last resort
    adlFallbackPoll();

  } catch (err) {
    console.error('[Bridge] Error in adobeDataLayer bridge:', err);
  }
})();
//</script>
