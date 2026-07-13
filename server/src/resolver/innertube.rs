use reqwest::Client;
use serde_json::{json, Value};
use super::client_contexts::{get_client_payload, ClientType};
use crate::models::stream_info::StreamInfo;
use crate::models::track::Track;
use std::time::{SystemTime, UNIX_EPOCH};

const PLAYER_URL: &str = "https://www.youtube.com/youtubei/v1/player";
const SEARCH_URL: &str = "https://www.youtube.com/youtubei/v1/search";

pub async fn search_songs(http_client: &Client, query: &str) -> Result<Vec<Track>, String> {
    let payload = json!({
        "context": {
            "client": {
                "clientName": "WEB_REMIX",
                "clientVersion": "1.20230508.01.00"
            }
        },
        "query": query,
        "params": "Eg-KAQwIARAAGAAgACgAMABqChAEEAMQCRAFEAo=" // Filter for songs
    });

    let res = http_client.post(SEARCH_URL)
        .json(&payload)
        .send()
        .await
        .map_err(|e| e.to_string())?;

    let data: Value = res.json().await.map_err(|e| e.to_string())?;
    
    let mut tracks = Vec::new();

    // Traverse the awful YouTube Music JSON response tree
    let contents = data["contents"]["tabbedSearchResultsRenderer"]["tabs"][0]
        ["tabRenderer"]["content"]["sectionListRenderer"]["contents"]
        .as_array();

    if let Some(sections) = contents {
        for section in sections {
            if let Some(items) = section["musicShelfRenderer"]["contents"].as_array() {
                for item in items {
                    if let Some(music_responsive_list_item_renderer) = item["musicResponsiveListItemRenderer"].as_object() {
                        let video_id = music_responsive_list_item_renderer["playlistItemData"]["videoId"].as_str().unwrap_or("").to_string();
                        
                        if video_id.is_empty() {
                            continue;
                        }

                        let title = music_responsive_list_item_renderer["flexColumns"][0]
                            ["musicResponsiveListItemFlexColumnRenderer"]["text"]["runs"][0]["text"]
                            .as_str()
                            .unwrap_or("Unknown Title")
                            .to_string();

                        let artist = music_responsive_list_item_renderer["flexColumns"][1]
                            ["musicResponsiveListItemFlexColumnRenderer"]["text"]["runs"][0]["text"]
                            .as_str()
                            .unwrap_or("Unknown Artist")
                            .to_string();

                        let thumbnails = music_responsive_list_item_renderer["thumbnail"]["musicThumbnailRenderer"]["thumbnail"]["thumbnails"].as_array();
                        let thumbnail = if let Some(thumbs) = thumbnails {
                            thumbs.last().and_then(|t| t["url"].as_str()).unwrap_or("").to_string()
                        } else {
                            "".to_string()
                        };

                        tracks.push(Track {
                            video_id,
                            title,
                            artist,
                            thumbnail,
                            duration: "0:00".to_string(), // Duration usually takes more parsing, skipping for brevity
                        });
                    }
                }
            }
        }
    }

    Ok(tracks)
}

pub async fn resolve_stream_with_client(
    http_client: &Client,
    video_id: &str,
    client: &ClientType,
) -> Result<StreamInfo, String> {
    let payload = get_client_payload(client, video_id);
    
    let res = http_client.post(PLAYER_URL)
        .json(&payload)
        .send()
        .await
        .map_err(|e| e.to_string())?;
        
    let data: Value = res.json().await.map_err(|e| e.to_string())?;
    
    // Check if playabilityStatus is OK
    let status = data["playabilityStatus"]["status"].as_str().unwrap_or("");
    if status != "OK" {
        return Err(format!("Unplayable status: {}", status));
    }

    // Try to find formats
    let formats = data["streamingData"]["adaptiveFormats"]
        .as_array()
        .or_else(|| data["streamingData"]["formats"].as_array());
        
    if let Some(formats_array) = formats {
        // Filter for audio only formats
        for format in formats_array {
            if let Some(mime) = format["mimeType"].as_str() {
                if mime.starts_with("audio/") {
                    if let Some(url) = format["url"].as_str() {
                        let now = SystemTime::now().duration_since(UNIX_EPOCH).unwrap().as_secs();
                        // Expire slightly early, standard is about 6 hours
                        let expires_at = now + (5 * 60 * 60); 
                        
                        return Ok(StreamInfo {
                            stream_url: url.to_string(),
                            expires_at,
                        });
                    }
                }
            }
        }
    }
    
    Err("No valid audio streams found".into())
}
