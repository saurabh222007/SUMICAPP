const prompt = `
You are a World-Class Principal Design Director and Lead Frontend Engineer (Apple Music, Teenage Engineering, Linear, Braun / Dieter Rams calibre).
We are building Sumic, an audiophile-grade, editorial music streaming web application.

Here is the current architectural and UI setup:
- App Structure: Slim left sidebar (logo, nav icons + vertical spine labels, queue/account at bottom) + main-shell + content pane.
- Home Screen (home-playcloud-layout):
  * Left stream col: Breadcrumb genre subnav pills + Editorial Hero Spotlight Banner (two-column card: left editorial text & play CTA, right artist image) + Genre Sections ('home-genre-section') each containing 'home-tracks-grid' with 'home-album-card'.
  * Right rail: Curator card + Live Audio Pulse Waveform card + Quick vibe chips / playlists.
- Song Card Elements:
  * .home-tracks-grid: currently "repeat(auto-fill, minmax(140px, 1fr))"
  * .home-album-card: padding 12px, .home-album-art-wrap (1:1 aspect-ratio, square, YouTube thumbnail img with object-fit: cover), .home-album-badge ('Track' / genre), floating hover circular play button, .home-album-title (white-space: nowrap), .home-album-artist.
- Miniplayer & Dock:
  * We currently have BOTH a floating Hi-Fi Dock (#dockMount) sitting at bottom: calc(var(--npbar-height, 84px) + 16px) AND a fixed bottom mini-player bar (.npbar) at height: 84px with 3-column grid (track info, center controls + scrubber, volume + expand).
  * This creates severe visual crowding, double bottom bars, uneven spacing, awkward song card wrapping, and thumbnail clipping.

The user asks:
"redesign this web app properly and accurately via maintaining ui element and ui , the app is build but the ui is uneven , miniplayer , the home screen the thumbnail of the song placements and even the every elements , take a look and make it perfect as any 10000$ SITE"

Provide a comprehensive, senior design audit and redesign masterplan:
1. Executive Aesthetic Direction: Define the exact design language (e.g. Tactile Hi-Fi Minimalist / Dark Monolithic / Editorial Dieter Rams / Teenage Engineering) so it feels like a $10,000 bespoke product, NOT a generic SaaS template.
2. Miniplayer & Dock Architecture: Exactly how to resolve the clash between #dockMount and #npbar. Should they be unified into a single iconic floating console or seamless dock? Provide the exact layout and dimension specifications.
3. Home Screen Composition & Proportions: Spatial rhythm, alignment of the Hero Banner with the Right Rail, grid gutter system, and sticky/scroll behavior.
4. Song Cards & Thumbnail Placement: Fix the 16:9 YouTube thumbnail into 1:1 or 4:3 cards without ugly letterboxing, card padding, typography scale, 2-line title clamp, badge positioning, and hover micro-interactions.
5. Concrete CSS System & Tokens: Spacing tokens, layout grid formulas, and CSS snippets ready for execution.
`;

async function main() {
  const res = await fetch('https://api.experientiallabs.ai/v1/chat/completions', {
    method: 'POST',
    headers: {
      'Authorization': 'Bearer xpl_e26ee92b4c2b974009bbe6a7975fa649ef4c8d65',
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'claude-opus-latest',
      messages: [
        { role: 'user', content: prompt }
      ]
    })
  });

  const data = await res.json();
  console.log('FULL_DATA:', JSON.stringify(data));
}

main().catch(console.error);
