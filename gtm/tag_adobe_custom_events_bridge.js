(function (window) {
  'use strict';

  var ACDL_NAME = 'adobeDataLayer';
  var GTM_DL_NAME = 'dataLayer';
  var BRIDGE_FLAG = '__acdlGtmBridgeInitialized';

  // ---------------------------------------------------------------------------
  // CONFIG - edit these arrays or hook them up to GTM variables if you want
  // ---------------------------------------------------------------------------
  // Null or empty => forward ALL events.
  // Examples:
  //   ['pageView', 'productsAdded']
  //   ['home*']           // prefix match (home, homeSectionClick, homeHeroClick)
  //   ['*']               // everything
  var ALLOWED_EVENT_NAMES = ['home*', 'mainNavClick']; // allowlist (case insensitive, supports prefix*)

  // Optional blocklist. These win over the allowlist.
  var BLOCKED_EVENT_NAMES = null; // e.g. ['debugEvent', 'test*']

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  if (window[BRIDGE_FLAG]) {
    return; // already initialized
  }
  window[BRIDGE_FLAG] = true;

  function getGtmDataLayer() {
    var dl = window[GTM_DL_NAME] = window[GTM_DL_NAME] || [];
    return dl;
  }

  function matchesList(name, list) {
    if (!list || !list.length) return false;
    var lowerName = String(name).toLowerCase();

    for (var i = 0; i < list.length; i++) {
      var raw = list[i];
      if (!raw) continue;
      var pattern = String(raw).toLowerCase();

      // wildcard for "everything"
      if (pattern === '*') return true;

      var starIndex = pattern.indexOf('*');
      if (starIndex >= 0) {
        // prefix match before the first *
        var prefix = pattern.slice(0, starIndex);
        if (prefix && lowerName.indexOf(prefix) === 0) return true;
      } else if (lowerName === pattern) {
        return true;
      }
    }
    return false;
  }

  function shouldForward(eventObject) {
    if (!eventObject || typeof eventObject !== 'object') return false;
    var name = eventObject.event;
    if (!name) return false; // we only care about ACDL "events", not pure data changes

    // Blocklist wins
    if (BLOCKED_EVENT_NAMES && BLOCKED_EVENT_NAMES.length &&
        matchesList(name, BLOCKED_EVENT_NAMES)) {
      return false;
    }

    // No allowlist configured => forward everything
    if (!ALLOWED_EVENT_NAMES || !ALLOWED_EVENT_NAMES.length) {
      return true;
    }

    return matchesList(name, ALLOWED_EVENT_NAMES);
  }

  function forwardToGtm(eventObject) {
    if (!shouldForward(eventObject)) return;

    try {
      var dl = getGtmDataLayer();

      // Keep the ACDL event object AS IS – no mutation
      dl.push({
        event: 'acdl.' + eventObject.event, // e.g. acdl.pageView, acdl.homeSectionClick
        acdlEventName: eventObject.event,
        acdl: eventObject
      });
    } catch (e) {
      if (window.console && console.warn) {
        console.warn('ACDL→GTM bridge push error:', e);
      }
    }
  }

  function registerBridge(dl) {
    // Listen to "all events" using the official special event type.
    // adobeDataLayer:event fires whenever any event object is pushed. :contentReference[oaicite:2]{index=2}
    var handler = function (eventObject) {
      forwardToGtm(eventObject);
    };

    // scope: "all" means past and future events, which avoids race conditions. :contentReference[oaicite:3]{index=3}
    dl.addEventListener('adobeDataLayer:event', handler, {
      scope: 'all'
    });

    if (window.console && console.info) {
      console.info('ACDL→GTM bridge registered (adobeDataLayer:event, scope=all)');
    }
  }

  function initBridge() {
    // Declare stub if needed, per Adobe setup docs :contentReference[oaicite:4]{index=4}
    var acdl = window[ACDL_NAME] = window[ACDL_NAME] || [];

    // Use the recommended "push a function" pattern so we only touch
    // addEventListener once ACDL is fully initialized. :contentReference[oaicite:5]{index=5}
    acdl.push(function (dl) {
      try {
        registerBridge(dl);
      } catch (e) {
        if (window.console && console.warn) {
          console.warn('ACDL→GTM bridge init error:', e);
        }
      }
    });
  }

  initBridge();
})(window);
