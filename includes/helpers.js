const ecommerceChannels = (source, medium, landingPage) => {
    return `
  CASE
    WHEN REGEXP_CONTAINS(${source}, r'(?i)google|bing|Bing_Shopping|yahoo|\(not set\)|\(unlinked SA360 account\)|ads\.google\.com|Search Traffic|SEM')
    AND REGEXP_CONTAINS(${medium}, r'(?i)cpc|Web_SearchEngine|Web_Search Engine|web_search|\(unlinked SA360 account\)|(?i)SEM') THEN 'RM - Paid Search'

    WHEN (REGEXP_CONTAINS(${source}, r'(?i)facebook|instagram|paidsocial')
    OR REGEXP_CONTAINS(${medium}, r'(?i)facebook|instagram|paidsocial'))
    AND NOT (REGEXP_CONTAINS(${source}, r'(?i)referral|organic')
    OR REGEXP_CONTAINS(${medium}, r'(?i)referral|organic')) THEN 'RM - Paid Social'

    ELSE '(Other)'
  END
  `;
};

module.exports = {
    ecommerceChannels
};

/*
Direct
CM Email
Organic Search

RM Paid Search
RM Paid Social
*/