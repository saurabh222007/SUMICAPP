from fastapi import FastAPI, HTTPException, Query
from fastapi.middleware.cors import CORSMiddleware
from ytmusicapi import YTMusic
import requests
import uvicorn
import yt_dlp

app = FastAPI(
    title="SUMIC YTMusic & Piped Backend",
    description="A fast, robust backend to search YouTube Music and resolve direct audio streams using Piped and local yt-dlp fallbacks."
)

# Enable CORS for frontend compatibility
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize ytmusicapi in public (unauthenticated) mode
ytmusic = YTMusic()

# List of public Piped API instances to query for streams with automatic fallback
PIPED_INSTANCES = [
    "https://pipedapi.kavin.rocks",
    "https://pipedapi.leptons.xyz",
    "https://pipedapi-libre.kavin.rocks",
    "https://api.piped.yt",
]

def get_direct_stream_url_piped(video_id: str) -> str:
    """
    Attempts to fetch the audio stream URL from public Piped API instances.
    Returns None if all instances fail.
    """
    for instance in PIPED_INSTANCES:
        url = f"{instance}/streams/{video_id}"
        try:
            print(f"[Piped] Trying instance: {url}")
            response = requests.get(url, timeout=6)
            if response.status_code == 200:
                data = response.json()
                audio_streams = data.get("audioStreams", [])
                if audio_streams:
                    stream_url = audio_streams[0].get("url")
                    if stream_url:
                        print(f"[Piped] Successfully resolved stream from: {instance}")
                        return stream_url
            else:
                print(f"[Piped] Instance {instance} returned status code {response.status_code}")
        except Exception as e:
            print(f"[Piped] Error connecting to {instance}: {e}")
    return None

def extract_stream_ytdlp(video_id: str) -> str:
    """
    Extracts direct YouTube audio stream URL using local yt-dlp library.
    """
    ydl_opts = {
        'format': 'bestaudio',
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
        'ignoreerrors': True,
        # Emulate Android/iOS client to bypass botguard
        'extractor_args': {
            'youtube': {
                'client': ['android', 'ios']
            }
        }
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(f"https://www.youtube.com/watch?v={video_id}", download=False)
            if info and "url" in info:
                return info["url"]
    except Exception as e:
        print(f"[yt-dlp] Direct extraction error: {e}")
    return None

def extract_stream_soundcloud(title: str, artist: str) -> str:
    """
    Searches SoundCloud for the given title/artist and extracts direct audio stream URL using yt-dlp.
    """
    query = f"scsearch1:{title} {artist}"
    ydl_opts = {
        'format': 'bestaudio',
        'quiet': True,
        'no_warnings': True,
        'nocheckcertificate': True,
        'ignoreerrors': True,
    }
    try:
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(query, download=False)
            if info and 'entries' in info and len(info['entries']) > 0:
                entry = info['entries'][0]
                if entry and "url" in entry:
                    return entry["url"]
    except Exception as e:
        print(f"[SoundCloud] search extraction error: {e}")
    return None

def resolve_stream(video_id: str, title: str = None, artist: str = None) -> str:
    """
    Combines Piped, direct yt-dlp, and SoundCloud search to guarantee a stream URL is resolved.
    """
    # Layer 1: Public Piped instances
    piped_url = get_direct_stream_url_piped(video_id)
    if piped_url:
        return piped_url
        
    print("[Resolve] Piped failed. Attempting Layer 2: direct local yt-dlp extraction...")
    
    # Layer 2: Local yt-dlp YouTube extraction
    ytdlp_url = extract_stream_ytdlp(video_id)
    if ytdlp_url:
        return ytdlp_url
        
    print("[Resolve] Direct yt-dlp extraction failed. Attempting Layer 3: SoundCloud search fallback...")
    
    # Layer 3: SoundCloud fallback
    if title and artist:
        sc_url = extract_stream_soundcloud(title, artist)
        if sc_url:
            return sc_url
            
    raise HTTPException(
        status_code=502,
        detail="All stream resolution tiers (Piped API, direct local yt-dlp, and SoundCloud fallback search) failed."
    )

@app.get("/search")
def search_songs(q: str = Query(..., description="The search query (song name or artist)")):
    """
    Searches YouTube Music for songs matching the query.
    Returns structured song items containing videoId, title, artist, and thumbnail.
    """
    try:
        print(f"[Search] Querying YouTube Music for: '{q}'")
        search_results = ytmusic.search(q, filter="songs")
        
        formatted_results = []
        for track in search_results:
            # Extract highest quality thumbnail
            thumbnails = track.get("thumbnails", [])
            thumbnail_url = thumbnails[-1].get("url") if thumbnails else ""
            
            # Extract artists
            artists = track.get("artists", [])
            artist_name = ", ".join([a.get("name", "") for a in artists]) if artists else "Unknown Artist"
            
            formatted_results.append({
                "videoId": track.get("videoId"),
                "title": track.get("title", "Unknown Title"),
                "artist": artist_name,
                "thumbnail": thumbnail_url,
                "duration": track.get("duration", "0:00")
            })
            
        return {"results": formatted_results}
    except Exception as e:
        print(f"[Search] Error during YTMusic search: {e}")
        raise HTTPException(status_code=500, detail=f"YouTube Music search failed: {str(e)}")

@app.get("/stream/{video_id}")
@app.get("/yt-stream/{video_id}")
def get_stream(video_id: str, title: str = None, artist: str = None):
    """
    Resolves the raw videoId to a direct progressive audio stream URL.
    Supports optional title and artist query parameters for SoundCloud search fallback routing.
    """
    audio_url = resolve_stream(video_id, title, artist)
    return {
        "videoId": video_id,
        "audio_url": audio_url
    }

@app.get("/play")
def play_song(q: str = Query(..., description="The search query of the song to play")):
    """
    Helper endpoint that searches for the query, grabs the first song result, 
    resolves its stream URL, and packages the complete track details for instant playback.
    """
    # 1. Search for the song
    search_data = search_songs(q)
    results = search_data.get("results", [])
    if not results:
        raise HTTPException(status_code=404, detail=f"No matches found for '{q}'")
    
    first_match = results[0]
    video_id = first_match.get("videoId")
    if not video_id:
        raise HTTPException(status_code=404, detail="No videoId found for first search result")
        
    # 2. Resolve the audio stream URL
    print(f"[Play] Resolving stream for '{first_match['title']}' ({video_id})")
    audio_url = resolve_stream(video_id, first_match.get("title"), first_match.get("artist"))
    
    # 3. Package response
    return {
        "videoId": video_id,
        "title": first_match.get("title"),
        "artist": first_match.get("artist"),
        "thumbnail": first_match.get("thumbnail"),
        "duration": first_match.get("duration"),
        "audio_url": audio_url
    }

if __name__ == "__main__":
    uvicorn.run("yt_music_backend:app", host="0.0.0.0", port=8000, reload=True)
