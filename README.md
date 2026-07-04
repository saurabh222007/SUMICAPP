# Sumic Backend

This directory contains the standalone, fully-functional Node.js backend for Sumic. You can copy this folder to any other location, run it independently, deploy it to platforms like Render, or expand it with additional APIs.

---

## 📂 Folder Contents

- `server.js` — The core Express application containing all API endpoints.
- `package.json` — Lists required dependencies (`express`) and running scripts.
- `.gitignore` — Prevents committing `node_modules` or `.env` configurations.

---

## 🚀 How to Run Locally

### 1. Install Dependencies
Make sure you have [Node.js](https://nodejs.org/) installed (v18+ recommended). Navigate to the `backend/` directory and install the dependencies:
```bash
npm install
```

### 2. Start the Server
Run the development command:
```bash
npm run dev
```
The console will display:
```text
  ╔══════════════════════════════════════════════════╗
  ║                SUMIC - BACKEND API               ║
  ║                                                  ║
  ║   Active Port: 3000                              ║
  ║   Local Server URL: http://localhost:3000        ║
  ║                                                  ║
  ╚══════════════════════════════════════════════════╝
```

---

## 🎵 Playlist Import Feature Explained

The Spotify Playlist Import endpoint is hosted at `POST /api/import-playlist`. Here is how it functions:

1. **Link Parsing**:
   - Accepts standard URL query parameter or request body: `url: "https://open.spotify.com/playlist/..."` or `spotify:playlist:...`.
   - Parses out the unique 22-character playlist ID using the helper `parseSpotifyPlaylistUrl`.

2. **Metadata Fetching (No API Key Required)**:
   - Fetches the public Spotify oEmbed API and open HTML page for the playlist embed (`https://open.spotify.com/embed/playlist/<playlistId>`).
   - Scrapes the `__NEXT_DATA__` JSON script tag in the HTML response, extracting the exact track list (`title` and `artist`) for the first 100 tracks.

3. **Multi-Source YouTube Translation**:
   - Because YouTube requires native video IDs (`videoId`) for playback:
     - The backend translates each track's text name (e.g., `"Blinding Lights The Weeknd"`) to a YouTube stream link.
     - Performs search queries across two search backends: **YouTube Direct Scrape** (scraping search results pages) and **Piped / Invidious Fallback Instances** (distributed community proxies) if direct scraping is blocked or throttled.
     - Queries are batched in groups of `10` parallel requests using `Promise.all` to maintain high speed and prevent YouTube from throttling the server.

4. **Return Schema**:
   - Returns a JSON response containing the playlist metadata and the translated list of tracks complete with YouTube video IDs, titles, and high-quality thumbnails.

---

## 🛠️ Adding More Features in the Future

### 🔑 Using Environment Variables
You can easily add a `.env` file inside the `backend` directory to manage secrets (like databases, APIs, session secrets).
1. Run `npm install dotenv` inside the backend directory.
2. Require it at the top of `server.js`:
   ```javascript
   require('dotenv').config();
   ```
3. Use secrets: `const MONGO_URI = process.env.MONGO_URI;`

### 🗄️ Adding a Database (MongoDB / PostgreSQL)
To persist user profiles, custom playlists, or play counts:
1. Install a database library (e.g., `npm install mongoose` or `npm install pg`).
2. Add your connection logic inside `server.js`:
   ```javascript
   const mongoose = require('mongoose');
   mongoose.connect(process.env.MONGO_URI)
     .then(() => console.log('Database connected!'))
     .catch(err => console.error(err));
   ```

### 🛣️ Creating New API Endpoints
You can easily define new routes under the **Future Extension Slots** section of `server.js`:
```javascript
// Create custom user playlists
app.post('/api/playlists', async (req, res) => {
  const { title, tracks, userId } = req.body;
  try {
    // 1. Validate the user and input data
    // 2. Write to your database (e.g. Playlist.create({ title, tracks, userId }))
    // 3. Return the created playlist
    res.status(201).json({ success: true, message: "Playlist created successfully!" });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});
```

---

## 🌐 Deploying to the Cloud

You can deploy this backend independently to hosting services like **Render**, **Railway**, or **Heroku**:
1. Create a new service pointing to your repository.
2. If your repository contains both the frontend and backend, set the **Root Directory** settings to `backend` (or customize the build command to `npm install` and start command to `node server.js`).
3. Make sure to define the frontend client configuration (e.g. `API_BASE` in `public/app.js`) to point to your new live API URL.
