use moka::future::Cache;
use std::time::Duration;

pub struct MemoryCache {
    // We can store Stringified JSON or specific models here
    // Stringified JSON is easiest for generic API responses
    cache: Cache<String, String>,
}

impl MemoryCache {
    pub fn new() -> Self {
        let cache = Cache::builder()
            .max_capacity(10_000)
            .time_to_live(Duration::from_secs(60 * 60)) // 1 hour TTL
            .build();
            
        Self { cache }
    }

    pub async fn get(&self, key: &str) -> Option<String> {
        self.cache.get(key).await
    }

    pub async fn insert(&self, key: String, value: String) {
        self.cache.insert(key, value).await;
    }
}
