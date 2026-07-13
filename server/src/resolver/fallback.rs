use reqwest::Client;
use super::innertube::resolve_stream_with_client;
use super::client_contexts::ClientType;
use crate::models::stream_info::StreamInfo;

pub async fn resolve_with_fallback(
    http_client: &Client,
    video_id: &str,
) -> Result<StreamInfo, String> {
    
    // Tier 1: Try Android
    tracing::info!("Attempting ANDROID client context for {}", video_id);
    match resolve_stream_with_client(http_client, video_id, &ClientType::Android).await {
        Ok(info) => return Ok(info),
        Err(e) => tracing::warn!("ANDROID failed: {}", e),
    }

    // Tier 2: Try iOS
    tracing::info!("Attempting IOS client context for {}", video_id);
    match resolve_stream_with_client(http_client, video_id, &ClientType::Ios).await {
        Ok(info) => return Ok(info),
        Err(e) => tracing::warn!("IOS failed: {}", e),
    }

    // Tier 3: Try TV
    tracing::info!("Attempting TV client context for {}", video_id);
    match resolve_stream_with_client(http_client, video_id, &ClientType::Tv).await {
        Ok(info) => return Ok(info),
        Err(e) => tracing::warn!("TV failed: {}", e),
    }

    // Smart replace (Search for another video with same title/artist)
    // This is a placeholder for where the actual smart replace search logic would go.
    // For now we just fail out if all tiers are exhausted.
    Err("All client contexts exhausted".into())
}
