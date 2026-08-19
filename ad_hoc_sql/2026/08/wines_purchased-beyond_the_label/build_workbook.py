"""Build the US companion workbook - US figures only, column structure matching the UK tab.

Figures are hard-coded from the query results in this directory (see README.md).
If you re-run the queries for a new period or brand, update the DATA / *_PAGES /
CHAN tables below to match before rebuilding.
"""
import os
import openpyxl
from openpyxl.styles import Font, PatternFill, Alignment, Border, Side
from openpyxl.utils import get_column_letter

WB = openpyxl.Workbook()

INK   = "16202B"
HEAD  = "1F3A4D"
BAND  = "EDEFF3"
ACC   = "7A1F3D"
GOOD  = "2C6B4F"
BAD   = "A3304A"

H1    = Font(name="Calibri", size=14, bold=True, color=INK)
H2    = Font(name="Calibri", size=11, bold=True, color=INK)
HDR   = Font(name="Calibri", size=10, bold=True, color="FFFFFF")
BODY  = Font(name="Calibri", size=10, color=INK)
BOLD  = Font(name="Calibri", size=10, bold=True, color=INK)
NOTE  = Font(name="Calibri", size=9, italic=True, color="5C6B7A")
GOODF = Font(name="Calibri", size=10, bold=True, color=GOOD)
BADF  = Font(name="Calibri", size=10, bold=True, color=BAD)

HDRFILL  = PatternFill("solid", fgColor=HEAD)
BANDFILL = PatternFill("solid", fgColor=BAND)
thin = Side(style="thin", color="D8DDE4")
BOX  = Border(bottom=thin)


def sheet(title, widths):
    ws = WB.create_sheet(title)
    for i, w in enumerate(widths, start=1):
        ws.column_dimensions[get_column_letter(i)].width = w
    ws.sheet_view.showGridLines = False
    return ws


def put(ws, row, values, font=BODY, fill=None, fmts=None, border=False):
    for i, v in enumerate(values, start=1):
        c = ws.cell(row=row, column=i, value=v)
        c.font = font
        if fill:
            c.fill = fill
        if border:
            c.border = BOX
        if fmts and i - 1 < len(fmts) and fmts[i - 1]:
            c.number_format = fmts[i - 1]
        if i > 1:
            c.alignment = Alignment(horizontal="right")
    return row + 1


def header(ws, row, cols):
    for i, v in enumerate(cols, start=1):
        c = ws.cell(row=row, column=i, value=v)
        c.font = HDR
        c.fill = HDRFILL
        c.alignment = Alignment(horizontal="right" if i > 1 else "left",
                                vertical="center", wrap_text=True)
    ws.row_dimensions[row].height = 30
    return row + 1


N0, N2, PCT, CUR = "#,##0", "#,##0.00", "0.0%", '"$"#,##0'

# ---------------------------------------------------------------- 1. Summary
ws = sheet("1. Summary", [34, 12, 13, 13, 14, 14, 12, 13, 12, 13])
r = 1
ws["A1"] = "US - Beyond the Label & Wines Purchased"; ws["A1"].font = H1; r = 3
ws.cell(row=r, column=1, value="Source: GA4 / analytics_unified. Period: 1 Jul 2025 - 30 Jun 2026 (FY25/26). Revenue USD, participation basis.").font = NOTE
r += 1
ws.cell(row=r, column=1, value="US only. Column structure follows the UK tab so the two files line up; the UK figures themselves are not reproduced here.").font = NOTE
r += 1
ws.cell(row=r, column=1, value="'Account' is any page under /jsp/account/ or, on LAW, /jsp/mytaste/ - and is the denominator for the % columns.").font = NOTE
r += 2

COLS = ["Based on page path + fragment", "Visits", "% of my account visits", "Conversion (participation)",
        "Order Revenue (inc) Participation", "% of my account revenue (participation)",
        "View PDP (next hit)", "View PDP (eventual path)", "Add to Bag (next hit)", "Add to Bag (eventual path)"]
FMTS = [None, N0, PCT, PCT, CUR, PCT, PCT, PCT, PCT, PCT]

DATA = {
    "US total (WSJ + LAW)": [
        ("Account", 375718, 1.0, .0735, 5490902, 1.0, .0688, .1039, .0140, .0363),
        ("Wines Purchased", 7029, .0187, .0617, 98302, .0179, .1788, .2364, .0124, .0546),
        ("Beyond the Label", 15156, .0403, .0494, 154978, .0282, .1260, .2482, .0076, .0361),
        ("Order History (comparator)", 196260, .5224, .0741, 3035824, .5529, .0968, .1399, .0101, .0352),
    ],
    "WSJ Wine": [
        ("Account", 249416, 1.0, .0752, 3560290, 1.0, .0687, .1012, .0131, .0332),
        ("Wines Purchased", 5254, .0211, .0699, 84076, .0236, .2141, .2705, .0137, .0590),
        ("Beyond the Label", 10788, .0433, .0482, 108574, .0305, .1320, .2538, .0082, .0360),
        ("Order History (comparator)", 130116, .5217, .0769, 2031944, .5707, .0971, .1393, .0098, .0337),
    ],
    "Laithwaites": [
        ("Account", 126302, 1.0, .0701, 1930612, 1.0, .0689, .1092, .0157, .0425),
        ("My Taste - Purchased", 1775, .0141, .0377, 14226, .0074, .0744, .1358, .0085, .0417),
        ("Beyond the Label", 4368, .0346, .0522, 46404, .0240, .1110, .2342, .0062, .0364),
        ("Order History (comparator)", 66144, .5237, .0686, 1003880, .5200, .0963, .1410, .0107, .0382),
    ],
}

for scope, rows in DATA.items():
    ws.cell(row=r, column=1, value=scope).font = H2
    r += 1
    r = header(ws, r, COLS)
    for i, row in enumerate(rows):
        f = BOLD if row[0] == "Account" else BODY
        fill = BANDFILL if row[0] == "Account" else None
        r = put(ws, r, list(row), font=f, fill=fill, fmts=FMTS, border=True)
    r += 1

ws.cell(row=r, column=1, value="Read: Wines Purchased beats Beyond the Label on conversion, revenue per visit and next-hit PDP in the US total and on WSJ. On LAW the ranking reverses - see sheet 4 for why.").font = NOTE

# ------------------------------------------------- 2. All account pages
ws = sheet("2. All account pages", [32, 11, 12, 15, 12, 12, 13, 12, 13, 74])
r = 1
ws["A1"] = "Every account page, ranked by next-hit PDP"; ws["A1"].font = H1; r = 3
ws.cell(row=r, column=1, value="'Next hit' = product page viewed on the very next pageview. 'Eventual' = anywhere later in the same visit.").font = NOTE
r += 1
ws.cell(row=r, column=1, value="URLs show the canonical form. Query strings (_requestid, promoCode) and ;jsessionid suffixes are stripped; hash routes are the page identity.").font = NOTE
r += 2

PCOLS = ["Page", "Visits", "% of account", "Revenue", "Conversion",
         "View PDP (next hit)", "View PDP (eventual)", "Add to Bag (next hit)",
         "Add to Bag (eventual)", "URL"]
PFMTS = [None, N0, PCT, CUR, PCT, PCT, PCT, PCT, PCT, None]

W = "https://www.wsjwine.com"
L = "https://www.laithwaites.com"
AD = "/jsp/account/common/account_details.jsp"

WSJ_PAGES = [
    ("Wines I've Purchased", 5254, .0211, 84076, .0699, .2141, .2705, .0137, .0590, W+AD+"#/purchased"),
    ("Top-Rated Wines", 254, .0010, 6465, .1339, .1457, .2795, .0157, .0984, W+AD+"#/top-rated"),
    ("Beyond the Label", 10788, .0433, 108574, .0482, .1320, .2538, .0082, .0360, W+AD+"#/beyond-the-label"),
    ("Favorites", 4986, .0200, 92361, .0766, .1278, .1839, .0191, .0734, W+AD+"#/favorites"),
    ("Recommendations", 490, .0020, 13522, .1408, .1245, .2306, .0306, .1143, W+AD+"#/recommendations"),
    ("Not For Me List", 779, .0031, 10465, .0680, .1091, .2105, .0051, .0321, W+AD+"#/not-for-me"),
    ("Order History", 129972, .5215, 2032150, .0770, .0972, .1391, .0099, .0337, W+"/jsp/account/common/account_order_history.jsp#/"),
    ("My Wine Cellar", 4109, .0165, 34559, .0431, .0428, .1042, .0080, .0360, W+AD+"#/wine-cellar"),
    ("Account Lists", 2385, .0096, 60886, .1237, .0314, .1736, .0306, .1229, W+"/jsp/account/common/account_lists.jsp"),
    ("Cellar Homepage", 1858, .0075, 33928, .0797, .0167, .1534, .0145, .0565, W+"/jsp/account/common/cellar_homepage.jsp"),
    ("Advantage", 12971, .0520, 273895, .1053, .0119, .0918, .0077, .0571, W+"/jsp/account/us/common/account_subscription.jsp"),
    ("Wine Preferences (gateway)", 12675, .0509, 240228, .0884, .0080, .2178, .0249, .0739, W+"/jsp/account/common/account_wine_preference.jsp"),
    ("Gift Cards / My Wine Credits", 5552, .0223, 177976, .1473, .0045, .1360, .0083, .0711, W+"/jsp/account/common/account_voucher_details.jsp"),
    ("My Clubs", 139786, .5608, 1268099, .0563, .0045, .0430, .0042, .0185, W+"/jsp/account/common/wp_summary.jsp"),
    ("Account (details home)", 131649, .5282, 2034805, .0806, .0044, .0755, .0046, .0351, W+AD+"#/"),
    ("Memberships", 7870, .0316, 109572, .0889, .0020, .0612, .0024, .0276, W+AD+"#/memberships"),
]
LAW_PAGES = [
    ("Beyond the Label", 4368, .0346, 46404, .0522, .1110, .2342, .0062, .0364, L+AD+"#/beyond-the-label"),
    ("Order History", 66151, .5238, 1003880, .0686, .0963, .1409, .0107, .0382, L+"/jsp/account/common/account_order_history.jsp#/"),
    ("My Taste - Purchased", 1775, .0141, 14226, .0377, .0744, .1358, .0085, .0417, L+"/jsp/mytaste/index.jsp#/purchased"),
    ("My Taste - Favorites", 2265, .0179, 22318, .0424, .0680, .1148, .0141, .0481, L+"/jsp/mytaste/index.jsp#/favorites"),
    ("Account Lists", 310, .0025, 7287, .1161, .0516, .1548, .0194, .0839, L+"/jsp/account/common/account_lists.jsp"),
    ("My Taste - landing (gateway)", 13490, .1068, 248238, .0801, .0454, .1504, .0153, .0741, L+"/jsp/mytaste/index.jsp#/"),
    ("My Taste - Preferences", 1514, .0120, 15064, .0489, .0172, .0733, .0046, .0396, L+"/jsp/mytaste/index.jsp#/preferences"),
    ("Unlimited", 5001, .0396, 115118, .1078, .0126, .0994, .0106, .0656, L+"/jsp/account/us/common/account_subscription.jsp"),
    ("My Clubs", 64379, .5097, 564570, .0446, .0116, .0532, .0064, .0245, L+"/jsp/account/common/wp_summary.jsp#/wine-club-summary"),
    ("Cellar Homepage", 11496, .0910, 133500, .0530, .0067, .0614, .0083, .0324, L+"/jsp/account/common/cellar_homepage.jsp"),
    ("Account (details home)", 62587, .4955, 1036985, .0773, .0050, .0829, .0066, .0426, L+AD+"#/"),
    ("Memberships", 3540, .0280, 43745, .0647, .0042, .0766, .0025, .0328, L+AD+"#/memberships"),
    ("Gift Cards / My Wine Credits", 1313, .0104, 60896, .2049, .0030, .1447, .0122, .0960, L+"/jsp/account/common/account_voucher_details.jsp"),
]

for name, pages in (("WSJ Wine - 249,246 account visits", WSJ_PAGES),
                    ("Laithwaites - 126,302 account visits", LAW_PAGES)):
    ws.cell(row=r, column=1, value=name).font = H2
    r += 1
    r = header(ws, r, PCOLS)
    for p in pages:
        focus = p[0] in ("Wines I've Purchased", "Beyond the Label", "My Taste - Purchased")
        r = put(ws, r, list(p), font=BOLD if focus else BODY,
                fill=BANDFILL if focus else None, fmts=PFMTS, border=True)
        # URL column: left-align and make it clickable
        c = ws.cell(row=r - 1, column=len(PCOLS))
        c.alignment = Alignment(horizontal="left")
        c.hyperlink = p[-1]
        c.font = Font(name="Calibri", size=9, color="26697A", underline="single",
                      bold=focus)
    r += 1

# ------------------------------------------------------------ 4. By channel
ws = sheet("3. By channel", [30, 11, 11, 10, 13, 12, 13, 13, 13, 13])
r = 1
ws["A1"] = "Focus pages by acquisition channel"; ws["A1"].font = H1; r = 3
for line in ["Figures on sheet 1 are unfiltered totals. This sheet shows the channel mix beneath them.",
             "Email is the largest single channel for both pages - neither is organic traffic.",
             "Channel is the session's last-non-direct source. Channels under 40 visits are omitted; totals include them."]:
    ws.cell(row=r, column=1, value=line).font = NOTE
    r += 1
r += 1

CCOLS = ["Page / channel", "Visits", "Users", "Txns", "Revenue", "Conversion",
         "PDP next hit", "PDP eventual", "ATB next hit", "ATB eventual"]
CFMTS = [None, N0, N0, N0, CUR, PCT, PCT, PCT, PCT, PCT]

CHAN = [
    ("WSJ Wine", None),
    ("Wines I've Purchased", (5254, 3844, 383, 84076, .0699, .2141, .2705, .0137, .0590)),
    ("   Email", (2938, 2377, 182, 41362, .0599, .1712, .2199, .0129, .0511)),
    ("   Direct", (1068, 744, 70, 15928, .0637, .2678, .3240, .0103, .0581)),
    ("   Organic Search", (422, 311, 35, 8194, .0782, .2536, .3104, .0095, .0711)),
    ("   Paid Search", (420, 341, 43, 8626, .0952, .2643, .3619, .0310, .0881)),
    ("   Direct Mail", (124, 77, 24, 4745, .1694, .3145, .4032, .0161, .0968)),
    ("   SMS", (83, 57, 8, 2147, .0964, .3373, .4217, .0241, .1205)),
    ("Beyond the Label", (10788, 8434, 551, 108574, .0482, .1320, .2538, .0082, .0360)),
    ("   Email", (4360, 3495, 191, 39635, .0422, .0991, .2119, .0073, .0317)),
    ("   Direct", (3286, 2823, 97, 21728, .0292, .1388, .2626, .0067, .0283)),
    ("   Paid Search", (1028, 862, 69, 13911, .0632, .1780, .3200, .0136, .0545)),
    ("   Organic Search", (967, 784, 69, 11777, .0600, .2037, .3320, .0103, .0455)),
    ("   SMS", (268, 227, 23, 5211, .0784, .1381, .2799, .0224, .0858)),
    ("   Narvar", (252, 203, 4, 639, .0159, .1151, .2579, .0000, .0238)),
    ("   Direct Mail", (246, 204, 59, 10094, .2236, .1341, .2154, .0041, .0447)),
    ("Laithwaites", None),
    ("My Taste - Purchased", (1775, 1248, 71, 14226, .0377, .0744, .1358, .0085, .0417)),
    ("   Email", (967, 699, 33, 8466, .0331, .0548, .1075, .0052, .0362)),
    ("   Direct", (412, 280, 11, 1732, .0267, .0728, .1214, .0097, .0340)),
    ("   Organic Search", (145, 124, 5, 780, .0345, .0966, .1931, .0138, .0414)),
    ("   Paid Search", (135, 120, 14, 2331, .0815, .1185, .2370, .0222, .0963)),
    ("Beyond the Label", (4368, 3450, 236, 46404, .0522, .1110, .2342, .0062, .0364)),
    ("   Email", (1588, 1299, 85, 16118, .0529, .0901, .2003, .0057, .0309)),
    ("   Direct", (1444, 1247, 60, 13755, .0388, .1025, .2244, .0035, .0284)),
    ("   Organic Search", (481, 371, 20, 4647, .0416, .1746, .3243, .0104, .0499)),
    ("   Paid Search", (352, 304, 20, 3781, .0540, .1534, .2642, .0142, .0682)),
    ("   Narvar", (208, 161, 10, 848, .0433, .0817, .2404, .0000, .0385)),
    ("   SMS", (121, 105, 10, 1978, .0826, .0826, .1983, .0165, .0496)),
]
r = header(ws, r, CCOLS)
for label, vals in CHAN:
    if vals is None:
        ws.cell(row=r, column=1, value=label).font = H2
        ws.cell(row=r, column=1).fill = BANDFILL
        r += 1
        continue
    is_total = not label.startswith("   ")
    r = put(ws, r, [label] + list(vals), font=BOLD if is_total else BODY, fmts=CFMTS, border=True)

# ------------------------------------------------------- 5. Navigation
ws = sheet("4. Navigation", [52, 26, 24, 46])
r = 1
ws["A1"] = "Why the US traffic comparison is not like for like"; ws["A1"].font = H1; r = 3
for line in ["Beyond the Label has two one-click entry points: the user dropdown (available site-wide) and the account sidebar.",
             "Wines Purchased has none - it sits behind 'Taste Preferences', a label that does not mention purchases, then a second menu.",
             "The preceding-pageview data below confirms this."]:
    ws.cell(row=r, column=1, value=line).font = NOTE
    r += 1
r += 1

r = header(ws, r, ["Route", "Clicks", "", "Notes"])
for row in [
    ("Beyond the Label - user dropdown", 1, "", "Available from every page on the site"),
    ("Beyond the Label - account sidebar", 1, "", "Second independent entry point"),
    ("WSJ Wines I've Purchased", 3, "", "Dropdown > Taste Preferences > Wine Cellar menu > page"),
    ("LAW My Taste - Purchased", 3, "", "Dropdown > Taste Preferences > My Taste landing > Purchased tab"),
]:
    r = put(ws, r, list(row), border=True)
r += 1

ws.cell(row=r, column=1, value="Gateway pass-through").font = H2
r += 1
r = header(ws, r, ["Gateway page", "Gateway visits", "Passed on", "Destination"])
for row in [
    ("WSJ - Wine Preferences", 12675, .415, "Wines I've Purchased (5,254)"),
    ("LAW - My Taste landing", 13490, .132, "My Taste Purchased (1,775)"),
]:
    r = put(ws, r, list(row), fmts=[None, N0, PCT, None], border=True)
ws.cell(row=r, column=1, value="Similar gateway traffic, very different pass-through. LAW's tab UI surfaces the Purchased view far less effectively.").font = NOTE
r += 2

ws.cell(row=r, column=1, value="Where each page is reached from (preceding pageview)").font = H2
r += 1
r = header(ws, r, ["Arrived from", "Pageviews", "Share", ""])
for grp, rows_ in [
    ("WSJ - Wines I've Purchased", [("Wine Preferences (gateway)", 3026, .467), ("Session entry - no prior page", 1359, .210),
                                    ("Repeat view or sibling Wine Cellar page", 688, .106), ("Login", 443, .068), ("Product page", 398, .061)]),
    ("WSJ - Beyond the Label", [("Login", 5098, .299), ("Order History", 2778, .163), ("Homepage", 2252, .132),
                                ("Other site page", 2043, .120), ("Session entry - no prior page", 1310, .077)]),
    ("LAW - Beyond the Label", [("Login", 2076, .359), ("Order History", 903, .156), ("Other site page", 711, .123), ("Homepage", 657, .114)]),
    ("LAW - My Taste Purchased", [("Session entry - no prior page", 828, .349), ("Other site page", 479, .202),
                                  ("Product page", 408, .172), ("My Taste landing", 253, .107)]),
]:
    ws.cell(row=r, column=1, value=grp).font = BOLD
    ws.cell(row=r, column=1).fill = BANDFILL
    r += 1
    for row in rows_:
        r = put(ws, r, list(row) + [""], fmts=[None, N0, PCT, None], border=True)
ws.cell(row=r, column=1, value="Beyond the Label is reached from wherever the visitor happened to be - the signature of a site-wide dropdown link. Wines Purchased is reached from one gateway page.").font = NOTE
r += 2

ws.cell(row=r, column=1, value="Where the 'Taste Preferences' dropdown link sends people next").font = H2
r += 1
ws.cell(row=r, column=1, value="The link into this section already exists. On WSJ it lands on the Wine Preferences form, which sends 0.6% of visitors to a product page; Wines Purchased, one click further along the same sidebar, sends 21.4%.").font = NOTE
r += 2
r = header(ws, r, ["Next page after the landing page", "WSJ - Wine Preferences form", "LAW - My Taste landing", ""])
for row in [
    ("Stayed on / reloaded the landing page", .328, .112),
    ("Onward to any sub-page of the section", .287, .032),
    ("     of which Wines Purchased", .123, .014),
    ("     of which Favorites", .063, .003),
    ("Straight to a product page", .006, .053),
    ("Left the site entirely", .064, .220),
    ("Elsewhere on the site", .315, .583),
]:
    r = put(ws, r, list(row) + [""], fmts=[None, PCT, PCT, None], border=True)
r += 1

ws.cell(row=r, column=1, value="What the design has to solve - constraints from the data, not a proposed design").font = H2
r += 1
for line in [
    "1. The route into this section already carries traffic; it arrives at the lowest-intent page in it. A landing-target and labelling question - no new menu item required.",
    "2. Adding Wines Purchased to the dropdown would place two 'wines you have bought' entries beside each other. The distinction is clear internally, probably not to a customer.",
    "3. Both brands split this content into its own section. WSJ navigates it with a left sidebar, LAW with horizontal tabs - and the sidebar moves far more people onward (28.7% vs 3.2%). LAW's tabbed landing also loses 22% of visitors straight off the site against WSJ's 6.4%.",
    "4. WSJ runs two sidebars - Account, and a 'Wine Cellar' one visible only inside that section. Of 236,792 account-section sessions, only 5.9% ever reach a Wine Cellar page, yet that is where nearly every high-intent page lives (Wines Purchased 21.4% next-hit PDP, Top-Rated 14.6%, Favorites 12.8%) against 0.2-1.2% for the Account sidebar's own pages, Order History aside.",
    "   Merging the sidebars is one answer; promoting two or three items into the Account sidebar is a smaller one. A combined list would run to ~17 entries, which carries its own risk - that trade-off is a design call, not one the data settles.",
    "5. Order History carries 52% of account visits while favouriting sits on pages ~2% of visitors reach. The imbalance is large; whether the action should move is a UX call.",
    "6. None of the above can be measured today - filter, create-PDF and favourite fire no events. Closing the tracking gap is the prerequisite, not the follow-up.",
]:
    ws.cell(row=r, column=1, value=line).font = BODY
    ws.cell(row=r, column=1).alignment = Alignment(wrap_text=False)
    r += 1

# ------------------------------------------------------------- 6. Notes
ws = sheet("5. Notes & definitions", [30, 100])
r = 1
ws["A1"] = "Definitions, caveats and known gaps"; ws["A1"].font = H1; r = 3
r = header(ws, r, ["Item", "Detail"])
for k, v in [
    ("Scope", "US only - WSJ Wine and Laithwaites. No UK figures are reproduced or re-analysed here; the UK read stays with the original workbook."),
    ("Source", "GA4 export via analytics_unified (BigQuery)."),
    ("Period", "1 Jul 2025 - 30 Jun 2026 (FY25/26)."),
    ("Currency", "USD throughout."),
    ("Assurance", "As a check on these figures: Adobe's own US read gives Wines Purchased 2.09% of account visits and Beyond the Label 4.15%. This GA4 analysis gives 2.11% and 4.33%. Two independent stacks within 0.2pp."),
    ("Visits", "Sessions that viewed the page at least once."),
    ("Account denominator", "Any page under /jsp/account/ or, on LAW, /jsp/mytaste/. LAW's Purchased and Favorites pages sit in My Taste, not the account section, so excluding it would understate LAW."),
    ("Participation basis", "Revenue and transactions credit the whole session to every account page it touched. Page rows therefore sum to more than the account total - this is a 'visited at least once' measure, not an attribution model."),
    ("View PDP (next hit)", "A product page viewed on the very next pageview after the page in question."),
    ("View PDP (eventual path)", "A product page viewed anywhere later in the same visit."),
    ("Add to Bag", "Same two definitions, applied to the add_to_cart event."),
    ("Page identity", "account_details.jsp and mytaste/index.jsp are hash-routed single-page apps: each sub-page fires its own pageview and the route appears only in the URL fragment. Page identity is therefore path + fragment. Path alone collapses every sub-page into one row."),
    ("Channel", "Session's last-non-direct source, using the project's channel_category. Describes how the session was acquired, not how the visitor reached that specific page."),
    ("GAP - interaction tracking", "Nothing fires for filter or create-PDF on the US pages. Whether the on-page functionality gets used cannot currently be answered."),
    ("GAP - shared URL", "Gift Cards and My Wine Credits both resolve to account_voucher_details.jsp with no fragment and cannot be separated without a tracking change."),
    ("CAVEAT - comparing to the UK", "The next-hit and eventual-path definitions used here are ours and will not necessarily match the UK workbook's. Before setting the two side by side, check that the windows are defined the same way - the ranking of pages within each market is the safer comparison."),
    ("CAVEAT - account home", "Sessions landing on account_details.jsp before routing onward count against the home row, so its share overstates it as a destination."),
]:
    c1 = ws.cell(row=r, column=1, value=k); c1.font = BOLD; c1.border = BOX
    c1.alignment = Alignment(vertical="top")
    c2 = ws.cell(row=r, column=2, value=v); c2.font = BODY; c2.border = BOX
    c2.alignment = Alignment(wrap_text=True, vertical="top")
    ws.row_dimensions[r].height = 30
    r += 1

del WB["Sheet"]
# Written to the repo root, two levels up from analysis/account_pages/
out = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "..",
                   "My Account - Beyond the Label My Purchased - US.xlsx")
out = os.path.normpath(out)
WB.save(out)
print("saved:", out)
