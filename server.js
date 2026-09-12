/**
 * Sumic – Standalone Express Backend
 * Handles YouTube Search, Autocomplete Suggestions,
 * Synced Lyrics (LRCLIB), YouTube Music Radio (Continuous Similar Track Queue),
 * and Spotify & YouTube Playlist Importers.
 */

const express = require('express');
const https = require('https');
const http = require('http');
const path = require('path');
const url = require('url');

const app = express();
const PORT = process.env.PORT || 3000;

// ── Serve static frontend ──────────────────────────────────────────────────
app.use(express.json({ limit: '2mb' }));
app.use(express.static(path.join(__dirname, 'public')));

app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({ error: 'Invalid JSON body.' });
  }
  next(err);
});

// ── CORS ──────────────────────────────────────────────────────────────────
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// ── Tiny fetch helper (no external deps) ──────────────────────────────────
function fetchUrl(rawUrl, options = {}) {
  return new Promise((resolve, reject) => {
    try {
      const parsed = new url.URL(rawUrl);
      const lib = parsed.protocol === 'https:' ? https : http;
      const reqOptions = {
        hostname: parsed.hostname,
        port: parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
        path: parsed.pathname + parsed.search,
        method: options.method || 'GET',
        headers: {
          'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept-Language': 'en-US,en;q=0.9',
          ...(options.headers || {})
        },
        timeout: options.timeout || 8000
      };

      const req = lib.request(reqOptions, (res) => {
        let data = '';
        res.setEncoding('utf8');
        res.on('data', chunk => { data += chunk; });
        res.on('end', () => resolve({
          ok: res.statusCode < 400,
          status: res.statusCode,
          text: () => Promise.resolve(data),
          json: () => {
            try { return Promise.resolve(JSON.parse(data)); }
            catch (e) { return Promise.reject(e); }
          }
        }));
      });

      req.on('timeout', () => { req.destroy(); reject(new Error('Request timed out')); });
      req.on('error', reject);
      req.end();
    } catch (e) {
      reject(e);
    }
  });
}

// ── Piped / Invidious instances ────────────────────────────────────────────
const instances = [
  { type: 'piped', url: 'https://pipedapi.kavin.rocks' },
  { type: 'piped', url: 'https://api.piped.private.coffee' },
  { type: 'invidious', url: 'https://inv.nadeko.net/api/v1' },
  { type: 'invidious', url: 'https://invidious.nerdvpn.de/api/v1' },
  { type: 'piped', url: 'https://pipedapi.adminforge.de' },
];

// ── YouTube direct scrape ──────────────────────────────────────────────────
async function searchYoutubeDirect(q) {
  try {
    const resp = await fetchUrl(`https://www.youtube.com/results?search_query=${encodeURIComponent(q)}`, { timeout: 9000 });
    if (!resp.ok) return null;
    const html = await resp.text();

    let dataStr = null;
    const m1 = html.match(/var ytInitialData = (\{.*?\});/);
    const m2 = html.match(/window\["ytInitialData"\] = (\{.*?\});/);
    if (m1) dataStr = m1[1];
    else if (m2) dataStr = m2[1];
    if (!dataStr) return null;

    const data = JSON.parse(dataStr);
    const sectionList = data.contents?.twoColumnSearchResultsRenderer?.primaryContents?.sectionListRenderer?.contents || [];
    const itemSection = sectionList.find(c => c.itemSectionRenderer)?.itemSectionRenderer?.contents || [];

    const results = itemSection
      .filter(v => v.videoRenderer)
      .slice(0, 16)
      .map(v => {
        const vr = v.videoRenderer;
        return {
          id: vr.videoId,
          title: vr.title?.runs?.[0]?.text || 'Unknown Title',
          author: vr.ownerText?.runs?.[0]?.text || '',
          duration: vr.lengthText?.simpleText || '0:00',
          thumbnail: `https://img.youtube.com/vi/${vr.videoId}/mqdefault.jpg`,
        };
      });
    return results.length > 0 ? results : null;
  } catch {
    return null;
  }
}

// ── Piped/Invidious fallback ───────────────────────────────────────────────
async function searchViaInstances(q, withFilter = true) {
  for (const inst of instances) {
    try {
      const filter = withFilter && inst.type === 'piped' ? '&filter=music_songs' : '';
      const searchUrl = inst.type === 'invidious'
        ? `${inst.url}/search?q=${encodeURIComponent(q)}`
        : `${inst.url}/search?q=${encodeURIComponent(q)}${filter}`;

      const resp = await fetchUrl(searchUrl, { timeout: 5000 });
      if (!resp.ok) continue;
      const data = await resp.json();
      let items = [];

      if (inst.type === 'invidious') {
        const arr = Array.isArray(data) ? data : (data.items || []);
        items = arr.filter(v => v.type === 'video').slice(0, 10).map(v => ({
          id: v.videoId, title: v.title, author: v.author || '',
          duration: v.lengthSeconds ? `${Math.floor(v.lengthSeconds / 60)}:${String(v.lengthSeconds % 60).padStart(2, '0')}` : '0:00',
          thumbnail: `https://img.youtube.com/vi/${v.videoId}/mqdefault.jpg`,
        }));
      } else {
        items = (data.items || []).slice(0, 10).map(v => ({
          id: (v.url || '').replace('/watch?v=', '') || v.videoId || '',
          title: v.title, author: v.uploaderName || '',
          duration: v.duration || '0:00',
          thumbnail: `https://img.youtube.com/vi/${(v.url || '').replace('/watch?v=', '')}/mqdefault.jpg`,
        }));
      }
      if (items.length > 0) return items;
    } catch { continue; }
  }
  return null;
}

// ── YouTube Music Radio Recommendations Engine (RDAMVM) ───────────────────
async function fetchYouTubeMusicRadio(videoId, trackTitle, artist) {
  if (!videoId) return [];
  try {
    const postData = JSON.stringify({
      context: { client: { clientName: 'WEB_REMIX', clientVersion: '1.20240101.01.00' } },
      playlistId: `RDAMVM${videoId}`,
      isAudioOnly: true
    });

    const parsed = new url.URL('https://music.youtube.com/youtubei/v1/next');
    const reqOptions = {
      hostname: parsed.hostname,
      path: parsed.pathname,
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Content-Length': Buffer.byteLength(postData),
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
        'Origin': 'https://music.youtube.com'
      },
      timeout: 8000
    };

    const data = await new Promise((resolve, reject) => {
      const req = https.request(reqOptions, res => {
        let body = '';
        res.setEncoding('utf8');
        res.on('data', chunk => body += chunk);
        res.on('end', () => {
          try { resolve(JSON.parse(body)); } catch (err) { reject(err); }
        });
      });
      req.on('error', reject);
      req.on('timeout', () => { req.destroy(); reject(new Error('timeout')); });
      req.write(postData);
      req.end();
    });

    const tabs = data.contents?.singleColumnMusicWatchNextResultsRenderer?.tabbedRenderer?.watchNextTabbedResultsRenderer?.tabs || [];
    const queue = tabs[0]?.tabRenderer?.content?.musicQueueRenderer?.content?.playlistPanelRenderer?.contents || [];

    const normTitle = (trackTitle || '').toLowerCase().replace(/[^a-z0-9]/g, '');

    const tracks = queue
      .map(i => i.playlistPanelVideoRenderer)
      .filter(Boolean)
      .filter(r => r.videoId && r.videoId !== videoId)
      .map(r => ({
        id: r.videoId,
        title: r.title?.runs?.[0]?.text || 'Unknown Title',
        author: r.longBylineText?.runs?.[0]?.text || r.shortBylineText?.runs?.[0]?.text || 'Unknown Artist',
        duration: r.lengthText?.runs?.[0]?.text || '3:30',
        thumbnail: `https://img.youtube.com/vi/${r.videoId}/mqdefault.jpg`
      }))
      .filter(t => {
        // Filter out same title / duplicate song variations
        const tNorm = t.title.toLowerCase().replace(/[^a-z0-9]/g, '');
        if (normTitle && normTitle.length > 3 && (tNorm.includes(normTitle) || normTitle.includes(tNorm))) {
          return false;
        }
        return true;
      });

    if (tracks.length > 0) return tracks;
  } catch (err) {
    // fallback
  }

  // Fallback: search for genre mix if YT Music next endpoint fails
  try {
    const searchQ = `${artist || ''} mix radio similar songs`.trim();
    const results = await searchYoutubeDirect(searchQ) || await searchViaInstances(searchQ, false);
    if (results && results.length > 0) {
      const normTitle = (trackTitle || '').toLowerCase().replace(/[^a-z0-9]/g, '');
      return results.filter(t => {
        if (t.id === videoId) return false;
        const tNorm = t.title.toLowerCase().replace(/[^a-z0-9]/g, '');
        if (normTitle && normTitle.length > 3 && (tNorm.includes(normTitle) || normTitle.includes(tNorm))) return false;
        return true;
      });
    }
  } catch (e) {}

  return [];
}

function parseSpotifyPlaylistUrl(rawUrl) {
  const value = String(rawUrl || '').trim();
  if (!value) return null;
  if (value.startsWith('spotify:playlist:')) return value.split(':').pop();

  try {
    const parsed = new URL(value);
    const parts = parsed.pathname.split('/').filter(Boolean);
    if (parsed.hostname.includes('spotify') && parts[0] === 'playlist') return parts[1];
  } catch {
    return null;
  }
  return null;
}

function parseYoutubePlaylistUrl(rawUrl) {
  const value = String(rawUrl || '').trim();
  if (!value) return null;
  try {
    const parsed = new URL(value);
    const list = parsed.searchParams.get('list');
    if (list) return list;
  } catch {
    if (value.startsWith('PL') || value.startsWith('RD') || value.startsWith('OLAK5uy_')) return value;
  }
  return null;
}

async function fetchSpotifyPlaylistTracks(playlistId) {
  try {
    const resp = await fetchUrl(
      `https://open.spotify.com/embed/playlist/${playlistId}`,
      { timeout: 10000, headers: { 'Accept': 'text/html' } }
    );
    if (resp.ok) {
      const html = await resp.text();
      const match = html.match(/<script id="__NEXT_DATA__" type="application\/json">([\s\S]*?)<\/script>/);
      if (match) {
        const json = JSON.parse(match[1]);
        const tracks =
          json?.props?.pageProps?.state?.data?.entity?.trackList ||
          json?.props?.pageProps?.state?.data?.entity?.items ||
          json?.props?.pageProps?.state?.data?.entity?.tracks?.items ||
          [];
        const title = json?.props?.pageProps?.state?.data?.entity?.name || 'Spotify Playlist';
        if (tracks.length > 0) {
          const list = tracks.slice(0, 100).map(t => ({
            title: t.title || t.name || t.track?.name || 'Unknown',
            artist: t.subtitle || t.artists?.map(a => a.name).join(', ') || t.track?.artists?.[0]?.name || t.track?.artists?.map(a => a.name).join(', ') || '',
          })).filter(t => t.title !== 'Unknown');
          return { tracks: list, title };
        }
      }
    }
  } catch { /* fall through */ }

  let playlistTitle = 'Imported Playlist';
  try {
    const oembed = await fetchUrl(
      `https://open.spotify.com/oembed?url=https://open.spotify.com/playlist/${playlistId}`,
      { timeout: 6000 }
    );
    if (oembed.ok) {
      const data = await oembed.json();
      if (data.title) playlistTitle = data.title;
    }
  } catch { /* ignore */ }

  return { fallback: true, title: playlistTitle };
}

async function searchOneTrack(query) {
  let results = await searchYoutubeDirect(query);
  if (results && results.length > 0) return results[0];
  results = await searchViaInstances(query, false);
  if (results && results.length > 0) return results[0];
  return null;
}

function parseSyncedLyrics(raw) {
  if (!raw) return [];
  const lines = [];
  const chunks = String(raw).split(/\r?\n/);
  chunks.forEach((chunk) => {
    const trimmed = chunk.trim();
    if (!trimmed) return;
    const match = trimmed.match(/^\[(\d{1,2}):(\d{2})(?:\.(\d{2,3}))?\]\s*(.*)$/);
    if (match) {
      const minutes = parseInt(match[1], 10) || 0;
      const seconds = parseInt(match[2], 10) || 0;
      const ms = parseInt(match[3] || '0', 10) / 1000;
      lines.push({
        time: minutes * 60 + seconds + ms,
        text: (match[4] || '').trim(),
      });
    } else {
      lines.push({ time: null, text: trimmed });
    }
  });
  return lines.filter(line => line.text);
}

// ── /api/suggestions endpoint ───────────────────────────────────────────────
app.get('/api/suggestions', async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (!q) return res.json({ suggestions: [] });

  try {
    const suggestUrl = `https://suggestqueries.google.com/complete/search?client=firefox&ds=yt&q=${encodeURIComponent(q)}`;
    const resp = await fetchUrl(suggestUrl, { timeout: 4000 });
    if (resp.ok) {
      const data = await resp.json();
      const suggestions = Array.isArray(data?.[1]) ? data[1].slice(0, 8) : [];
      return res.json({ suggestions });
    }
  } catch (e) {}
  return res.json({ suggestions: [] });
});

// ── /api/radio endpoint (Similar Genre / Related Tracks Engine) ──────────────
app.get('/api/radio', async (req, res) => {
  const videoId = String(req.query.id || '').trim();
  const track = String(req.query.track || '').trim();
  const artist = String(req.query.artist || '').trim();

  if (!videoId && !track) {
    return res.status(400).json({ error: 'Please provide videoId or track title.' });
  }

  try {
    const tracks = await fetchYouTubeMusicRadio(videoId, track, artist);
    return res.json({ tracks });
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Failed to fetch radio recommendations' });
  }
});

// ── /api/lyrics endpoint ───────────────────────────────────────────────────
app.get('/api/lyrics', async (req, res) => {
  const track = String(req.query.track || '').trim();
  const artist = String(req.query.artist || '').trim();
  if (!track) {
    return res.status(400).json({ error: 'Please provide a track title.' });
  }

  try {
    const searchUrl = new URL('https://lrclib.net/api/search');
    searchUrl.searchParams.set('track_name', track);
    if (artist) searchUrl.searchParams.set('artist_name', artist);

    const response = await fetchUrl(searchUrl.toString(), { timeout: 8000 });
    if (!response.ok) {
      return res.status(404).json({ error: 'No lyrics found.' });
    }

    const data = await response.json();
    const match = Array.isArray(data) ? (data.find(item => !item.instrumental && item.syncedLyrics) || data[0]) : null;
    if (!match) {
      return res.status(404).json({ error: 'No lyrics found.' });
    }

    const rawLyrics = match.syncedLyrics || match.plainLyrics || '';
    const lines = parseSyncedLyrics(rawLyrics);
    const fallback = lines.length > 0 ? lines : [{ text: match.plainLyrics || 'Lyrics are not available for this track yet.', time: null }];

    return res.json({ lines: fallback, isSynced: Boolean(match.syncedLyrics) });
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Unable to fetch lyrics.' });
  }
});

// ── /api/search endpoint ───────────────────────────────────────────────────
app.get('/api/search', async (req, res) => {
  const q = String(req.query.q || '').trim();
  if (!q) {
    return res.status(400).json({ error: 'Please provide a search query.' });
  }

  try {
    const directResults = await searchYoutubeDirect(q);
    const results = directResults && directResults.length > 0
      ? directResults
      : await searchViaInstances(q, true);

    if (results && results.length > 0) {
      return res.json({ results });
    }

    return res.json({ results: [], error: 'No results found.' });
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Search failed.' });
  }
});

// ── /api/import-playlist (Spotify) endpoint ────────────────────────────────
app.post('/api/import-playlist', async (req, res) => {
  try {
    const rawUrl = req.body?.url || req.query?.url || '';
    const value = String(rawUrl).trim();

    if (!value) {
      return res.status(400).json({ error: 'Please provide a Spotify playlist link.' });
    }

    const playlistId = parseSpotifyPlaylistUrl(value);
    if (!playlistId) {
      return res.status(400).json({ error: 'Please provide a valid Spotify playlist link (e.g. https://open.spotify.com/playlist/...)' });
    }

    let spotifyData = await fetchSpotifyPlaylistTracks(playlistId);
    let playlistTitle = spotifyData?.title || 'Spotify Playlist';
    let queries = [];

    if (spotifyData && Array.isArray(spotifyData.tracks) && spotifyData.tracks.length > 0) {
      queries = spotifyData.tracks.map(t => t.artist ? `${t.title} ${t.artist}` : t.title);
    } else if (spotifyData && spotifyData.fallback) {
      playlistTitle = spotifyData.title || 'Imported Playlist';
      let foundViaPiped = false;
      for (const inst of instances) {
        if (inst.type !== 'piped') continue;
        try {
          const searchUrl = `${inst.url}/search?q=${encodeURIComponent(playlistTitle)}&filter=playlists`;
          const resp = await fetchUrl(searchUrl, { timeout: 5000 });
          if (!resp.ok) continue;
          const data = await resp.json();
          const playlists = (data.items || []).filter(i => i.type === 'playlist' || i.playlistType);
          if (playlists.length > 0) {
            const plId = playlists[0].url?.replace('/playlist?list=', '') || playlists[0].playlistId;
            if (plId) {
              const plResp = await fetchUrl(`${inst.url}/playlists/${plId}`, { timeout: 6000 });
              if (plResp.ok) {
                const plData = await plResp.json();
                const relatedStreams = plData.relatedStreams || [];
                queries = relatedStreams.slice(0, 100).map(s => `${s.title} ${s.uploaderName || ''}`);
                playlistTitle = plData.name || playlistTitle;
                foundViaPiped = true;
                break;
              }
            }
          }
        } catch { continue; }
      }

      if (!foundViaPiped) {
        const searchResults = await searchYoutubeDirect(playlistTitle) ||
                              await searchViaInstances(playlistTitle, false);
        if (searchResults && searchResults.length > 0) {
          const tracks = searchResults.slice(0, 50).map(t => ({
            id: t.id,
            title: t.title,
            author: t.author || 'Unknown',
            thumbnail: `https://img.youtube.com/vi/${t.id}/mqdefault.jpg`,
          }));
          return res.json({ playlist: { id: playlistId, title: playlistTitle, owner: 'Spotify', tracks } });
        }
        return res.status(502).json({ error: 'Could not fetch playlist tracks. Please check the playlist link and try again.' });
      }
    }

    if (queries.length === 0) {
      return res.status(502).json({ error: 'No tracks found in this playlist.' });
    }

    const tracks = [];
    const batchSize = 10;
    for (let i = 0; i < Math.min(queries.length, 60); i += batchSize) {
      const batch = queries.slice(i, i + batchSize);
      const results = await Promise.all(batch.map(q => searchOneTrack(q)));
      for (const t of results) {
        if (t) {
          tracks.push({
            id: t.id,
            title: t.title,
            author: t.author || 'Unknown',
            thumbnail: `https://img.youtube.com/vi/${t.id}/mqdefault.jpg`,
          });
        }
      }
    }

    if (tracks.length === 0) {
      return res.status(502).json({ error: 'Found playlist but could not match tracks on YouTube. Try again.' });
    }

    res.json({
      playlist: {
        id: playlistId,
        title: playlistTitle,
        owner: 'Spotify',
        tracks,
      },
    });
  } catch (e) {
    res.status(500).json({ error: e.message || 'Unable to import playlist.' });
  }
});

// ── /api/import-youtube-playlist endpoint ──────────────────────────────────
app.post('/api/import-youtube-playlist', async (req, res) => {
  try {
    const rawUrl = req.body?.url || req.query?.url || '';
    const playlistId = parseYoutubePlaylistUrl(rawUrl);

    if (!playlistId) {
      return res.status(400).json({ error: 'Please provide a valid YouTube playlist link or ID.' });
    }

    try {
      const resp = await fetchUrl(`https://www.youtube.com/playlist?list=${encodeURIComponent(playlistId)}`, { timeout: 9000 });
      if (resp.ok) {
        const html = await resp.text();
        let dataStr = null;
        const m1 = html.match(/var ytInitialData = (\{.*?\});/);
        const m2 = html.match(/window\["ytInitialData"\] = (\{.*?\});/);
        if (m1) dataStr = m1[1];
        else if (m2) dataStr = m2[1];

        if (dataStr) {
          const data = JSON.parse(dataStr);
          const title = data.metadata?.playlistMetadataRenderer?.title || 'YouTube Playlist';
          const tabs = data.contents?.twoColumnBrowseResultsRenderer?.tabs || [];
          const tabContent = tabs[0]?.tabRenderer?.content?.sectionListRenderer?.contents || [];
          const itemSection = tabContent[0]?.itemSectionRenderer?.contents || [];
          const playlistItems = itemSection[0]?.playlistVideoListRenderer?.contents || [];

          const tracks = playlistItems
            .filter(item => item.playlistVideoRenderer)
            .map(item => {
              const vr = item.playlistVideoRenderer;
              return {
                id: vr.videoId,
                title: vr.title?.runs?.[0]?.text || vr.title?.simpleText || 'Unknown',
                author: vr.shortBylineText?.runs?.[0]?.text || 'YouTube',
                duration: vr.lengthText?.simpleText || '0:00',
                thumbnail: `https://img.youtube.com/vi/${vr.videoId}/mqdefault.jpg`,
              };
            });

          if (tracks.length > 0) {
            return res.json({
              playlist: {
                id: playlistId,
                title,
                owner: 'YouTube',
                tracks,
              }
            });
          }
        }
      }
    } catch { /* try piped instances */ }

    // Fallback to Piped API instances
    for (const inst of instances) {
      if (inst.type !== 'piped') continue;
      try {
        const pResp = await fetchUrl(`${inst.url}/playlists/${playlistId}`, { timeout: 6000 });
        if (pResp.ok) {
          const pData = await pResp.json();
          const tracks = (pData.relatedStreams || []).slice(0, 100).map(s => ({
            id: (s.url || '').replace('/watch?v=', '') || s.videoId,
            title: s.title,
            author: s.uploaderName || 'YouTube',
            duration: s.duration || '0:00',
            thumbnail: `https://img.youtube.com/vi/${(s.url || '').replace('/watch?v=', '')}/mqdefault.jpg`,
          })).filter(t => t.id);

          if (tracks.length > 0) {
            return res.json({
              playlist: {
                id: playlistId,
                title: pData.name || 'YouTube Playlist',
                owner: pData.uploader || 'YouTube',
                tracks,
              }
            });
          }
        }
      } catch { continue; }
    }

    return res.status(404).json({ error: 'Could not find or import this YouTube playlist.' });
  } catch (e) {
    res.status(500).json({ error: e.message || 'Unable to import YouTube playlist.' });
  }
});

// ── Fallback → index.html (SPA) ───────────────────────────────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

app.listen(PORT, () => {
  console.log(`\n  ╔═══════════════════════════════════════════╗`);
  console.log(`  ║   Sumic Music Engine                     ║`);
  console.log(`  ║   Running on: http://localhost:${PORT}        ║`);
  console.log(`  ╚═══════════════════════════════════════════╝\n`);
});
