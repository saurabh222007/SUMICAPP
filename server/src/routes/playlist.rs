use axum::{extract::Query, Json};
use serde::Deserialize;
use serde_json::json;

#[derive(Deserialize)]
pub struct PlaylistParams {
    pub id: String,
}

pub async fn playlist_handler(Query(params): Query<PlaylistParams>) -> Json<serde_json::Value> {
    Json(json!({
        "id": params.id,
        "title": "Playlist Title",
        "tracks": []
    }))
}
