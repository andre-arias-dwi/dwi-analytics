# Account-section page analysis (Beyond the Label / Wines Purchased)

Ad-hoc analysis run Aug 2026 for the Beyond the Label retirement decision. Answers:
which account pages get visited, what visitors do next, and where the traffic comes from.

Not part of the Dataform graph — these are standalone `bq` queries. All are parameterised
on `d_start` / `d_end` and a brand list, so re-running for another period or brand is a
two-line change at the top of each file.

## Running them

```powershell
Get-Content 01_summary.sql -Raw | bq --project_id=tough-healer-395417 --headless=true --quiet query --use_legacy_sql=false --format=pretty
```

(File-via-stdin matters on Windows — passing SQL inline gets mangled by PowerShell's
backtick escaping and `bq` then blocks reading stdin.)

## The queries

| File | Answers |
| --- | --- |
| `01_summary.sql` | Headline rows: Account benchmark, the two focus pages, Order History as comparator. US total and per brand. Mirrors the UK workbook's column structure. |
| `02_all_account_pages.sql` | Every account page ranked, both brands, with the next-click / eventual split. |
| `03_focus_by_channel.sql` | The two focus pages by `channel_category` and `lnd_source_medium`, with an unfiltered total. |
| `04_entry_paths.sql` | Preceding pageview for each focus page — how people arrive. |
| `05_gateway_onward.sql` | Where the "Taste Preferences" landing pages send people next. |
| `06_section_crossover.sql` | Overlap between the Account section and the Wine Cellar section audiences. |
| `build_workbook.py` | Renders the shareable `.xlsx` into the repo root. Needs `openpyxl`. |

`build_workbook.py` has the figures **hard-coded** from the query output — it does not hit
BigQuery. Re-run the queries first, then update its tables.

## Definitions

- **Visits** — sessions that viewed the page at least once.
- **Next hit** — `view_item` / `add_to_cart` at `page_number + 1` (the very next pageview).
- **Eventual** — the same events at any later `hit_number` in the session.
- **Participation** — full session revenue credited to every account page the session
  touched. Page rows therefore sum to more than the section total. Not an attribution model.
- **Account denominator** — any page under `/jsp/account/` or, on LAW, `/jsp/mytaste/`.

## Gotchas that will bite on a re-run

1. **Hash routes are the page identity.** `account_details.jsp` and LAW's
   `mytaste/index.jsp` are single-page apps: each sub-page fires its own `page_view` and the
   route appears only in `page_fragment`. Keying on `page_path` alone collapses ~15 distinct
   pages into one row. Always key on path + normalised fragment.
2. **Normalise the fragment.** `NULL`, `#`, `#/` all mean the default view. Fragments also
   carry query strings (`#/beyond-the-label?utm_source=narvar&...`). The regex
   `^#?/?([^?&]*)` handles both.
3. **Strip `;jsessionid=`** from `page_path`, or every session becomes its own page — this
   produced thousands of junk rows on the first run.
4. **LAW's Purchased and Favorites are under `/jsp/mytaste/`, not `/jsp/account/`.** Scope
   the account denominator to both or LAW is badly understated.
5. **`hit_number` / `page_number`** in `fact_ga4_events` are clean and fully populated;
   `page_number` increments per pageview, `hit_number` per event. The intraday model sets
   both to NULL, so don't extend this to intraday without reworking the sequencing.

## Scope note

US properties only (WSJ, LAW). The UK read belongs to a separate Adobe property that is not
in this warehouse; the companion workbook deliberately does not reproduce or re-cut it.
Next-hit / eventual window definitions here are ours and are not known to match the UK
workbook's — check before setting the two side by side.
