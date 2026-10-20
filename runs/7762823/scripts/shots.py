"""Headless screenshots of the Discovery Engine UI, taken on the compute node itself.

    python3 shots.py OUTDIR before|after [UI_URL]

Runs inside the Playwright image, on the same network as the stack, so it reaches the UI at
127.0.0.1:15173 without an SSH tunnel. "before" is taken ahead of registering the card, "after"
once it is registered and the engine has resynced. Writes PNGs and shots-<phase>.json.
"""
import json, os, sys
from playwright.sync_api import sync_playwright

OUT, PHASE = sys.argv[1], sys.argv[2]
UI = sys.argv[3] if len(sys.argv) > 3 else "http://127.0.0.1:15173/"
QUERY = "unsupervised end-member extraction from geoscience mixtures"
CARD_TITLE = "EMMA Benchmark"
log = []


def step(name):
    """Run one screenshot step; a failure is recorded and the next step still runs."""
    def wrap(fn):
        try:
            note = fn() or ""
            log.append({"shot": name, "ok": True, "note": note})
        except Exception as e:  # noqa: BLE001
            log.append({"shot": name, "ok": False, "note": repr(e)[:400]})
        print(f"shot {name}: {log[-1]['ok']} {log[-1]['note']}", flush=True)
    return wrap


# The bundled corpus is other teams' work, published without a licence. So the screenshots show
# only what the run record shows for it: titles, types and scores. Every other card's description,
# tags and I/O modes are covered by a grey bar, and so are the facet lists (tags, data modes) when
# other cards are on screen, since those are pooled from them. The registered card is left as is.
REDACT_CSS = """
[data-redact] { background: #c9ced6 !important; border-radius: 4px !important; }
[data-redact], [data-redact] * { color: transparent !important; text-shadow: none !important;
  border-color: transparent !important; box-shadow: none !important; }
[data-redact] * { background: transparent !important; }
[data-redact] img, [data-redact] svg { visibility: hidden !important; }
"""
REDACT_JS = """keep => {
  const parts = '.card-tile-desc, .card-tile-tags, .card-tile-io, .palette-card-desc, .palette-card-tags, '
              + '.palette-card-io, .palette-preview-desc, .palette-preview-tags, .palette-preview-modes';
  document.querySelectorAll('[data-redact]').forEach(p => p.removeAttribute('data-redact'));
  let others = 0;
  for (const el of [...document.querySelectorAll('.card-tile, .palette-card, .palette-preview')].filter(e => e.offsetParent !== null)) {
    const title = el.querySelector('.card-tile-title, .palette-card-title, .palette-preview-name');
    if (title && title.innerText.includes(keep)) continue;
    others++;
    el.querySelectorAll(parts).forEach(p => p.setAttribute('data-redact', ''));
  }
  if (others) document.querySelectorAll('.facet-tag, .facet-code').forEach(p => p.setAttribute('data-redact', ''));
  return others;
}"""
TEXT_JS = """() => [...document.querySelectorAll('body *')].filter(e => {
    const r = e.getBoundingClientRect();
    return e.children.length === 0 && r.width > 0 && r.height > 0 && r.bottom > 0 && r.top < innerHeight
      && r.right > 0 && r.left < innerWidth && e.innerText && e.innerText.trim();
  }).map(e => e.closest('[data-redact]') ? '[redacted]' : e.innerText.trim()).join('\\n')"""
redacted = {}


def snap(name):
    """Redact, screenshot, and keep a text dump of what is visible (for checking; not published)."""
    page.add_style_tag(content=REDACT_CSS)
    redacted[name] = page.evaluate(REDACT_JS, CARD_TITLE)
    page.wait_for_timeout(300)
    page.screenshot(path=f"{OUT}/{name}.png")
    os.makedirs(f"{OUT}/text", exist_ok=True)
    with open(f"{OUT}/text/{name}.txt", "w") as f:
        f.write(page.evaluate(TEXT_JS))


def tiles_text(n=6):
    t = page.locator(".card-tile .card-tile-title")
    return " | ".join(t.nth(i).inner_text() for i in range(min(n, t.count())))


def open_app():
    page.goto(UI, wait_until="networkidle", timeout=90000)
    page.wait_for_timeout(1500)
    # With no LLM configured the app opens Settings once. A click on the overlay closes it.
    if page.locator(".settings-overlay").count():
        if PHASE == "before":
            snap("01_settings_no_llm")
        page.locator(".settings-overlay").first.click(position={"x": 8, "y": 8})
        page.wait_for_timeout(500)


def explore_search(query):
    page.locator("button.sidebar-item", has_text="Explore").click()
    page.wait_for_selector(".card-tile", timeout=60000)
    page.wait_for_timeout(800)
    page.fill(".explore-search-input", query)
    with page.expect_response(lambda r: "/api/v1/discover" in r.url, timeout=60000):
        page.press(".explore-search-input", "Enter")
    page.wait_for_timeout(1500)


with sync_playwright() as p:
    browser = p.chromium.launch(args=["--disable-dev-shm-usage"])
    ctx = browser.new_context(viewport={"width": 1440, "height": 900}, color_scheme="light")
    page = ctx.new_page()
    open_app()

    if PHASE == "before":
        @step("02_workspace")
        def _():
            snap("02_workspace")

        @step("03_explore_corpus")
        def _():
            page.locator("button.sidebar-item", has_text="Explore").click()
            page.wait_for_selector(".card-tile", timeout=60000)
            page.wait_for_timeout(1000)
            snap("03_explore_corpus")
            return page.locator(".explore-count").first.inner_text()

        @step("04_search_before")
        def _():
            explore_search(QUERY)
            snap("04_search_before")
            return f"{page.locator('.explore-count').first.inner_text()}: {tiles_text()}"

    else:
        @step("05_search_after")
        def _():
            explore_search(QUERY)
            snap("05_search_after")
            return f"{page.locator('.explore-count').first.inner_text()}: {tiles_text()}"

        @step("06_card_detail")
        def _():
            page.locator(".card-tile", has_text=CARD_TITLE).first.click()
            page.wait_for_selector(".explore-detail .detail-head-title", timeout=30000)
            page.wait_for_timeout(1500)
            snap("06_card_detail")

        @step("07_card_relationships")
        def _():
            page.locator(".explore-detail-body").get_by_text("Relationships", exact=False).first.scroll_into_view_if_needed()
            page.locator(".explore-detail-body").first.evaluate("e => e.scrollBy(0, -40)")
            page.wait_for_timeout(600)
            snap("07_card_relationships")

        @step("08_card_raw")
        def _():
            page.locator(".explore-detail-tabs button", has_text="Raw").click()
            page.wait_for_timeout(1200)
            snap("08_card_raw")

        for q, name in (("hyperspectral unmixing benchmark Jasper Ridge", "09_search_jasper"),
                        ("stream water chemistry end-member mixing analysis Panola", "10_search_panola")):
            @step(name)
            def _(q=q, name=name):
                if page.locator(".detail-head-close").count():
                    page.locator(".detail-head-close").first.click()
                explore_search(q)
                snap(name)
                return f"{page.locator('.explore-count').first.inner_text()}: {tiles_text()}"

        @step("11_workspace_palette")
        def _():
            page.locator("button.sidebar-item", has_text="Workspace").click()
            page.wait_for_timeout(1000)
            page.keyboard.press("Control+k")
            page.wait_for_selector(".palette-search-input", timeout=10000)
            page.fill(".palette-search-input", "end-member extraction")
            page.keyboard.press("Enter")
            page.wait_for_timeout(2500)
            snap("11_workspace_palette")
            page.keyboard.press("Escape")

        @step("12_create_card")
        def _():
            page.locator("button.sidebar-item", has_text="Create a Card").click()
            page.wait_for_timeout(2000)
            snap("12_create_card")

    browser.close()

for entry in log:
    entry["other_cards_redacted"] = redacted.get(entry["shot"], 0)
json.dump(log, open(f"{OUT}/shots-{PHASE}.json", "w"), indent=1)
