WHERE
  s.geo.country = 'United States'
  AND s.device.web_info.hostname = 'www.wsjwine.com'
  AND (
    -- Current Year: full months + MTD
    (
      s.session_date BETWEEN DATE '2024-09-01' AND DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 DAY) -- full months
      OR s.session_date BETWEEN DATE_TRUNC(CURRENT_DATE(), MONTH) AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) -- MTD
    )

    OR

    -- Previous Year: full months + MTD match
    (
      s.session_date BETWEEN DATE '2023-09-01' AND DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 YEAR + 1 DAY) -- full months
      OR s.session_date BETWEEN DATE_SUB(DATE_TRUNC(CURRENT_DATE(), MONTH), INTERVAL 1 YEAR)
                          AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR + 1 DAY) -- MTD match
    )
  )



s.session_date BETWEEN '2024-09-01' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY) -- Current Year
      OR
      s.session_date BETWEEN '2023-09-01' AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 YEAR + 1 DAY) -- Previous Year