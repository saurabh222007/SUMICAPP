use axum::{extract::Query, Json};
use reqwest::Client;
use serde::Deserialize;
use serde_json::json;
use crate::resolver::fallback::resolve_with_fallback;

#[derive(Deserialize)]
pub struct StreamParams {
    pub id: String,
}

pub async fn stream_handler(Query(params): Query<StreamParams>) -> Json<serde_json::Value> {
    // Check cache here...

    let client = Client::new();
    match resolve_with_fallback(&client, &params.id).await {
        Ok(stream_info) => {
            // Cache result here...
            
            Json(json!({
                "videoId": params.id,
                "audio_url": stream_info.stream_url,
                "expires_at": stream_info.expires_at,
            }))
        }
        Err(e) => {
            Json(json!({
                "error": true,
                "message": e
            }))
        }
    }
}
