use axum::Json;
use serde_json::json;

pub async fn home_handler() -> Json<serde_json::Value> {
    Json(json!({
        "shelves": [
            {
                "title": "Top Hits",
                "items": []
            }
        ]
    }))
}
