pub mod memory;
pub mod store;

use std::sync::Arc;
use tokio::sync::OnceCell;

// Example state holding both caches
pub struct CacheState {
    pub memory: memory::MemoryCache,
    pub store: store::SqliteStore,
}

static CACHE_STATE: OnceCell<Arc<CacheState>> = OnceCell::const_new();

pub async fn init_cache(database_url: &str) -> Arc<CacheState> {
    let memory = memory::MemoryCache::new();
    let store = store::SqliteStore::new(database_url).await.expect("Failed to init SQLite store");
    
    let state = Arc::new(CacheState { memory, store });
    CACHE_STATE.set(state.clone()).unwrap();
    state
}

pub fn get_cache() -> Arc<CacheState> {
    CACHE_STATE.get().expect("Cache not initialized").clone()
}
