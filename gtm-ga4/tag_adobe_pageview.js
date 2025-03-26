<script>
function handleAdobePageView(event) {
  if (event && event.event === 'pageView' && event.eventData && event.eventData.user) {
    var user = event.eventData.user;
    var page = event.eventData.page || {};

    window.dataLayer = window.dataLayer || [];
    window.dataLayer.push({
      event: 'adobe_page_view',
      login_status: user.loginType || 'unknown',
      user_id: user.customerId || 'unknown',
      active_state: user.state || 'unknown',
      page_name: page.pageName || 'unknown',
      page_type: page.pageType || 'unknown'
    });
  }
}

(function() {
  try {
    window.adobeDataLayer = window.adobeDataLayer || [];

    // Process any existing pageView events
    window.adobeDataLayer.forEach(handleAdobePageView);

    // Monkey-patch adobeDataLayer.push to catch future pageViews
    var originalPush = window.adobeDataLayer.push;
    window.adobeDataLayer.push = function(event) {
      originalPush.call(this, event);
      handleAdobePageView(event);
    };
  } catch (err) {
    console.error('[adobeDataLayer bridge] Error:', err);
  }
})();
</script>
