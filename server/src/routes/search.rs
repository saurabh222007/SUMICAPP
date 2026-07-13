use axum::{extract::Query, Json};
use reqwest::Client;
use serde::Deserialize;
use serde_json::json;
use crate::resolver::innertube::search_songs;

#[derive(Deserialize)]
pub struct SearchParams {
    pub q: String,
}

pub async fn search_handler(Query(params): Query<SearchParams>) -> Json<serde_json::Value> {
    let client = Client::new();
    
    match search_songs(&client, &params.q).await {
        Ok(tracks) => {
            Json(json!({
                "results": tracks
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
