import sys
import os

# Ensure current directory is in path
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from yt_music_backend import search_songs, resolve_stream

def run_tests():
    print("==================================================")
    print("      SUMIC Backend Testing - Piped & YTMusic     ")
    print("==================================================")

    # 1. Test YTMusic Search
    query = "Sidhu Moose Wala 47"
    print(f"\n[Test 1] Searching YTMusic for: '{query}'")
    try:
        search_res = search_songs(query)
        results = search_res.get("results", [])
        if not results:
            print("[ERROR] Search returned 0 results!")
            return False
        
        first_song = results[0]
        print(f"[OK] Search OK! Found: '{first_song['title']}' by '{first_song['artist']}' (videoId: {first_song['videoId']})")
    except Exception as e:
        print(f"[ERROR] Search Failed with error: {e}")
        return False

    # 2. Test Piped / Local Stream Resolution
    video_id = first_song['videoId']
    print(f"\n[Test 2] Resolving stream for videoId: {video_id}")
    try:
        audio_url = resolve_stream(video_id, first_song['title'], first_song['artist'])
        if not audio_url:
            print("[ERROR] Stream URL is empty or null!")
            return False
            
        print("[OK] Stream Resolution OK!")
        print(f"Direct Audio URL (truncated): {audio_url[:120]}...")
        
        # 3. Test if URL is accessible (returns a valid media header / bytes)
        print("\n[Test 3] Verifying media stream accessibility...")
        import requests
        media_resp = requests.head(audio_url, timeout=10, allow_redirects=True)
        print(f"Media Status Code: {media_resp.status_code}")
        print(f"Content-Type: {media_resp.headers.get('Content-Type')}")
        print(f"Content-Length: {media_resp.headers.get('Content-Length')} bytes")
        
        if media_resp.status_code in [200, 206]:
            print("[OK] Media stream is alive and accessible! Playback will work flawlessly.")
            return True
        else:
            print(f"[ERROR] Media server returned invalid status: {media_resp.status_code}")
            return False
    except Exception as e:
        print(f"[ERROR] Stream resolution failed with error: {e}")
        return False

if __name__ == "__main__":
    success = run_tests()
    if success:
        print("\nALL TESTS PASSED! Backend is fully functional and ready to stream.")
        sys.exit(0)
    else:
        print("\nSOME TESTS FAILED! Please inspect errors above.")
        sys.exit(1)
