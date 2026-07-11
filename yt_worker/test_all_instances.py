import requests

instances = [
    "https://pipedapi.kavin.rocks",
    "https://pipedapi.leptons.xyz",
    "https://pipedapi-libre.kavin.rocks",
    "https://pipedapi.drgns.space",
    "https://pipedapi.colt.top",
    "https://piped-api.lvk.st",
    "https://pipedapi.ox.ly",
    "https://pipedapi.riv.al",
    "https://piped-api.garudalinux.org",
    "https://pipedapi.adminforge.de",
    "https://pipedapi.qdi.re",
    "https://pipedapi.split.rocks",
    "https://piped-api.mha.fi",
    "https://api.piped.yt",
]

video_id = "iU7cDCmEiUw"  # Sidhu Moose Wala - 47

print("Scanning public Piped API instances for stream health...")
print("=========================================================")

active_instances = []

for instance in instances:
    url = f"{instance}/streams/{video_id}"
    try:
        # Lower timeout to scan fast
        resp = requests.get(url, timeout=5)
        if resp.status_code == 200:
            data = resp.json()
            audio_streams = data.get("audioStreams", [])
            if audio_streams:
                stream_url = audio_streams[0].get("url")
                if stream_url:
                    print(f"[ONLINE] {instance} - Stream URL resolved successfully!")
                    active_instances.append(instance)
                else:
                    print(f"[EMPTY]  {instance} - Returned 200 but no audio stream URLs found.")
            else:
                print(f"[EMPTY]  {instance} - Returned 200 but audioStreams is empty.")
        else:
            print(f"[DOWN]   {instance} - Returned HTTP {resp.status_code}")
    except Exception as e:
        print(f"[ERROR]  {instance} - Connection failed: {e}")

print("=========================================================")
print(f"Scan complete. Active instances list: {active_instances}")
