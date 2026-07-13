use axum::{
    routing::get,
    Router,
};
use std::net::SocketAddr;
use tower_http::cors::{Any, CorsLayer};
use tracing_subscriber;

mod cache;
mod config;
mod models;
mod resolver;
mod routes;
mod test_yt;

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt::init();

    // CORS configuration
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Initialize state/cache
    // let state = cache::init_cache().await;

    // Build router
    let app = Router::new()
        .route("/search", get(routes::search::search_handler))
        .route("/stream", get(routes::stream::stream_handler))
        .route("/related", get(routes::related::related_handler))
        .route("/playlist", get(routes::playlist::playlist_handler))
        .route("/lyrics", get(routes::lyrics::lyrics_handler))
        .route("/home", get(routes::home::home_handler))
        .layer(cors);
        // .with_state(state);

    let addr = SocketAddr::from(([0, 0, 0, 0], 8000));
    tracing::info!("Server listening on {}", addr);
    
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
