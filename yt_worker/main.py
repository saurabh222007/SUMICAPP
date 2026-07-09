from fastapi import FastAPI, HTTPException
import yt_dlp

app = FastAPI()

@app.get("/yt-stream/{video_id}")
async def get_yt_stream(video_id: str):
    try:
        ydl_opts = {
            'format': 'bestaudio',
            'quiet': True,
            'no_warnings': True,
            # Render/datacenter bypass strategies
            'nocheckcertificate': True,
            'ignoreerrors': True,
            'no_color': True,
        }
        with yt_dlp.YoutubeDL(ydl_opts) as ydl:
            info = ydl.extract_info(f"https://www.youtube.com/watch?v={video_id}", download=False)
            if not info:
                raise HTTPException(status_code=404, detail="Could not extract video info")
            
            audio_url = info.get("url")
            title = info.get("title")
            duration = info.get("duration")
            
            if not audio_url:
                raise HTTPException(status_code=404, detail="Audio stream URL not found")
                
            return {
                "audio_url": audio_url,
                "title": title,
                "duration": duration
            }
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))
