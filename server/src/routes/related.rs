use axum::{extract::Query, Json};
use serde::Deserialize;
use serde_json::json;

#[derive(Deserialize)]
pub struct RelatedParams {
    pub id: String,
}

pub async fn related_handler(Query(params): Query<RelatedParams>) -> Json<serde_json::Value> {
    Json(json!({
        "results": [
            {
                "videoId": format!("{}-related-1", params.id),
                "title": "Related Song 1",
                "artist": "Related Artist",
                "thumbnail": "https://dummyimage.com/600x400/000/fff",
                "duration": "3:45"
            }
        ]
    }))
}
