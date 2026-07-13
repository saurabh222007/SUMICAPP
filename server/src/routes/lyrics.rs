use axum::{extract::Query, Json};
use serde::Deserialize;
use serde_json::json;

#[derive(Deserialize)]
pub struct LyricsParams {
    pub id: String,
}

pub async fn lyrics_handler(Query(params): Query<LyricsParams>) -> Json<serde_json::Value> {
    Json(json!({
        "id": params.id,
        "lyrics": "🎵 La la la... 🎵"
    }))
}
