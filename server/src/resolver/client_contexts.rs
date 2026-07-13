use serde_json::json;

pub enum ClientType {
    Android,
    Ios,
    Tv,
}

pub fn get_client_payload(client: &ClientType, video_id: &str) -> serde_json::Value {
    let (client_name, client_version) = match client {
        ClientType::Android => ("ANDROID_MUSIC", "6.22.52"),
        ClientType::Ios => ("IOS", "18.39.2"),
        ClientType::Tv => ("TVHTML5", "7.20230419.00.00"),
    };

    json!({
        "context": {
            "client": {
                "clientName": client_name,
                "clientVersion": client_version,
                "hl": "en",
                "gl": "US"
            }
        },
        "videoId": video_id,
        "playbackContext": {
            "contentPlaybackContext": {
                "signatureTimestamp": 19999 // A valid recent timestamp or dynamic
            }
        }
    })
}
