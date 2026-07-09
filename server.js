/**
 * Sumic – standalone Express backend
 * Handles YouTube search (scraping + Piped/Invidious fallback)
 * Serves the frontend from /public (relative to project root)
 * Resolves lyrics from LrcLib
 * Imports Spotify playlists without an API key
 */

const express = require('express');
const https = require('https');
const http = require('http');
const path = require('path');
const url = require('url');

// spotify-url-info initialization
const customFetch = (url, options = {}) => {
  const headers = {
    'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.7',
    'Accept-Language': 'en-US,en;q=0.9',
    'Referer': 'https://open.spotify.com/',
    'Origin': 'https://open.spotify.com',
    ...(options.headers || {})
  };
  return fetch(url, { ...options, headers });
};
const { getDetails } = require('spotify-url-info')(customFetch);

// youtubei.js initialization
const { Innertube } = require('youtubei.js');
let youtube;
async function getYoutube() {
  if (!youtube) {
    youtube = await Innertube.create();
  }
  return youtube;
}

const app = express();
const PORT = process.env.PORT || 3000;

// ── Serve static frontend (Relative to backend folder) ────────────────────
app.use(express.json({ limit: '1mb' }));
app.use(express.static(path.join(__dirname, '../public')));

app.use((err, req, res, next) => {
  if (err instanceof SyntaxError && err.status === 400 && 'body' in err) {
    return res.status(400).json({ error: 'Invalid JSON body.' });
  }
  next(err);
});

// ── CORS (Ensures frontend on other hosts/ports can connect) ──────────────
app.use((req, res, next) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');
  if (req.method === 'OPTIONS') return res.sendStatus(204);
  next();
});

// ── Tiny fetch helper (no external dependencies) ──────────────────────────
function fetchUrl(rawUrl, options = {}) {
  return new Promise((resolve, reject) => {
    const parsed = new url.URL(rawUrl);
    const lib = parsed.protocol === 'https:' ? https : http;
    const reqOptions = {
      hostname: parsed.hostname,
      port: parsed.port || (parsed.protocol === 'https:' ? 443 : 80),
      path: parsed.pathname + parsed.search,
      method: options.method || 'GET',
      headers: {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/120.0.0.0 Safari/537.36',
        'Accept-Language': 'en-US,en;q=0.9',
        ...(options.headers || {})
      },
      timeout: options.timeout || 8000
    };

    const req = lib.request(reqOptions, (res) => {
      let data = '';
      res.setEncoding('utf8');
      res.on('data', chunk => { data += chunk; });
      res.on('end', () => {
        try {
          resolve({
            ok: res.statusCode < 400,
            status: res.statusCode,
            text: () => Promise.resolve(data),
            json: () => Promise.resolve(JSON.parse(data))
          });
        } catch (e) {
          resolve({
            ok: res.statusCode < 400,
            status: res.statusCode,
            text: () => Promise.resolve(data),
            json: () => Promise.reject(new Error('Invalid JSON received'))
          });
        }
      });
    });

    req.on('timeout', () => { req.destroy(); reject(new Error('Request timed out')); });
    req.on('error', reject);
    req.end();
  });
}

// ── Piped / Invidious instances for YouTube Fallback ──────────────────────
const instances = [
  { type: 'piped',     url: 'https://pipedapi.kavin.rocks' },
  { type: 'piped',     url: 'https://api.piped.private.coffee' },
  { type: 'invidious', url: 'https://inv.nadeko.net/api/v1' },
  { type: 'invidious', url: 'https://invidious.nerdvpn.de/api/v1' },
  { type: 'piped',     url: 'https://pipedapi.adminforge.de' },
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
      .slice(0, 10)
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
        items = arr.filter(v => v.type === 'video').slice(0, 8).map(v => ({
          id: v.videoId, title: v.title, author: v.author || '',
          duration: v.lengthSeconds || 0,
          thumbnail: `https://img.youtube.com/vi/${v.videoId}/mqdefault.jpg`,
        }));
      } else {
        items = (data.items || []).slice(0, 8).map(v => ({
          id: (v.url || '').replace('/watch?v=', '') || v.videoId || '',
          title: v.title, author: v.uploaderName || '',
          duration: v.duration,
          thumbnail: `https://img.youtube.com/vi/${(v.url || '').replace('/watch?v=', '')}/mqdefault.jpg`,
        }));
      }
      if (items.length > 0) return items;
    } catch { continue; }
  }
  return null;
}

// ── Spotify Playlist Parsing ────────────────────────────────────────────────
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

/**
 * Fetch track list from a public Spotify playlist by scraping the
 * open.spotify.com embed page — no API key required.
 * Returns an array of { title, artist } objects.
 */
async function fetchSpotifyPlaylistTracks(playlistId) {
  try {
    const playlistUrl = `https://open.spotify.com/playlist/${playlistId}`;
    const details = await getDetails(playlistUrl);
    if (details && details.tracks) {
      return details.tracks.map(t => ({
        title: t.name || 'Unknown',
        artist: t.artist || '',
      })).filter(t => t.title !== 'Unknown');
    }
  } catch (e) {
    console.error('fetchSpotifyPlaylistTracks error:', e);
  }
  return { fallback: true, title: 'Imported Playlist' };
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

// ── /api/lyrics endpoint ────────────────────────────────────────────────
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
    const match = Array.isArray(data) ? (data.find(item => !item.instrumental) || data[0]) : null;
    if (!match) {
      return res.status(404).json({ error: 'No lyrics found.' });
    }

    const rawLyrics = match.syncedLyrics || match.plainLyrics || '';
    const lines = parseSyncedLyrics(rawLyrics);
    const fallback = lines.length > 0 ? lines : [{ text: match.plainLyrics || 'Lyrics are not available for this track yet.', time: null }];

    return res.json({ lines: fallback });
  } catch (e) {
    return res.status(500).json({ error: e.message || 'Unable to fetch lyrics.' });
  }
});

// ── /api/search endpoint ────────────────────────────────────────────────
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

// ── /api/stream endpoint ────────────────────────────────────────────────
app.get('/api/stream', async (req, res) => {
  const id = String(req.query.id || '').trim();
  if (!id) {
    return res.status(400).json({ error: 'Please provide a track ID.' });
  }

  // 1. Try youtubei.js streaming first (resolves directly from YouTube using Innertube engine)
  try {
    const yt = await getYoutube();
    const stream = await yt.download(id, {
      type: 'audio',
      quality: 'best',
      format: 'any'
    });
    
    res.setHeader('Content-Type', 'audio/mpeg');
    res.setHeader('Accept-Ranges', 'bytes');

    const reader = stream.getReader();
    const pump = async () => {
      try {
        const { done, value } = await reader.read();
        if (done) {
          res.end();
          return;
        }
        res.write(Buffer.from(value));
        pump();
      } catch (err) {
        console.error('Error pumping stream:', err);
        res.destroy();
      }
    };
    pump();
    return;
  } catch (err) {
    console.error('youtubei.js download failed, falling back to dynamic Invidious proxy:', err.message);
  }

  // 2. Fallback to Dynamic Invidious Proxy list (resolves using public Invidious proxies with local=true)
  try {
    const resp = await fetchUrl('https://api.invidious.io/instances.json?sort_by=type,health', { timeout: 3500 });
    if (resp.ok) {
      const instancesData = await resp.json();
      const workingUris = [];
      for (const [name, inst] of instancesData) {
        if (inst.type === 'https' && inst.monitor && !inst.monitor.down) {
          workingUris.push(inst.uri);
        }
      }
      for (const uri of workingUris.slice(0, 6)) {
        try {
          console.log(`Redirecting to Invidious proxy: ${uri}/latest_version?id=${id}&local=true`);
          return res.redirect(`${uri}/latest_version?id=${id}&local=true`);
        } catch (_) {}
      }
    }
  } catch (e) {
    console.error('Dynamic Invidious fallback failed:', e.message);
  }

  // 3. Last resort fallback: Hardcoded Piped instances
  for (const inst of instances) {
    if (inst.type !== 'piped') continue;
    try {
      const resp = await fetchUrl(`${inst.url}/streams/${id}`, { timeout: 4000 });
      if (!resp.ok) continue;
      const data = await resp.json();
      const audioStreams = data.audioStreams || [];
      if (audioStreams.length > 0) {
        return res.redirect(audioStreams[0].url);
      }
    } catch {
      continue;
    }
  }

  return res.status(502).json({ error: 'Could not resolve streaming URL from YouTube or dynamic proxies.' });
});

// ── /api/import-playlist endpoint (Spotify Import Feature) ──────────────
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

    // Step 1: Fetch actual track names from the Spotify playlist page
    let spotifyTracks = await fetchSpotifyPlaylistTracks(playlistId);
    let playlistTitle = 'Imported Playlist';
    let queries = [];

    if (Array.isArray(spotifyTracks) && spotifyTracks.length > 0) {
      // We got real track data from Spotify embed
      queries = spotifyTracks.map(t => t.artist ? `${t.title} ${t.artist}` : t.title);
      playlistTitle = 'Spotify Playlist';
    } else if (spotifyTracks && spotifyTracks.fallback) {
      // Embed scrape failed — search YouTube for the playlist title to find
      // a matching YouTube playlist, then pull its tracks via Piped
      playlistTitle = spotifyTracks.title || 'Imported Playlist';

      // Try to find playlist on YouTube via Piped playlist search
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
            // Fetch first playlist's tracks
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
        // Last resort: search YouTube directly for the playlist name as a query
        const searchResults = await searchYoutubeDirect(playlistTitle) ||
                              await searchViaInstances(playlistTitle, false);
        if (searchResults && searchResults.length > 0) {
          const tracks = searchResults.slice(0, 100).map(t => ({
            id: t.id,
            title: t.title,
            author: t.author || 'Unknown',
            thumbnail: `https://img.youtube.com/vi/${t.id}/mqdefault.jpg`,
          }));
          return res.json({ playlist: { id: playlistId, title: playlistTitle, owner: 'Spotify', tracks } });
        }
        return res.status(502).json({ error: 'Could not fetch playlist tracks. The playlist may be private or Spotify is blocking requests. Try again in a moment.' });
      }
    }

    if (queries.length === 0) {
      return res.status(502).json({ error: 'No tracks found in this playlist.' });
    }

    // Step 2: Search YouTube for each track (run up to 10 at a time to avoid throttling)
    const tracks = [];
    const batchSize = 10;
    for (let i = 0; i < Math.min(queries.length, 100); i += batchSize) {
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
      return res.status(502).json({ error: 'Found playlist but could not match any tracks on YouTube. Try again.' });
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

/* 
 * FUTURE EXTENSION SLOTS:
 * Add your custom route handlers here (e.g. database endpoints for saving playlists, user profiles, etc.)
 * 
 * Example:
 * app.post('/api/user/save-playlist', (req, res) => {
 *   // DB save logic here
 *   res.json({ success: true });
 * });
 */

// ── Fallback → index.html (SPA support) ───────────────────────────────────
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, '../public', 'index.html'));
});

// ── Start Server ──────────────────────────────────────────────────────────
app.listen(PORT, () => {
  console.log(`\n  ╔══════════════════════════════════════════════════╗`);
  console.log(`  ║                SUMIC - BACKEND API               ║`);
  console.log(`  ║                                                  ║`);
  console.log(`  ║   Active Port: ${PORT}                              ║`);
  console.log(`  ║   Local Server URL: http://localhost:${PORT}      ║`);
  console.log(`  ║                                                  ║`);
  console.log(`  ╚══════════════════════════════════════════════════╝\n`);
});
