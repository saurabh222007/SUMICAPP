use sqlx::{sqlite::SqlitePoolOptions, Pool, Sqlite};

pub struct SqliteStore {
    pool: Pool<Sqlite>,
}

impl SqliteStore {
    pub async fn new(database_url: &str) -> Result<Self, sqlx::Error> {
        let pool = SqlitePoolOptions::new()
            .max_connections(5)
            .connect(database_url)
            .await?;
            
        // Setup table if not exists
        sqlx::query(
            "CREATE TABLE IF NOT EXISTS api_cache (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL,
                expires_at INTEGER NOT NULL
            );"
        )
        .execute(&pool)
        .await?;

        Ok(Self { pool })
    }

    pub async fn get(&self, key: &str) -> Option<String> {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs() as i64;

        let result: Result<(String,), _> = sqlx::query_as(
            "SELECT value FROM api_cache WHERE key = ? AND expires_at > ?"
        )
        .bind(key)
        .bind(now)
        .fetch_one(&self.pool)
        .await;

        result.map(|row| row.0).ok()
    }

    pub async fn insert(&self, key: &str, value: &str, expires_in_secs: u64) {
        let now = std::time::SystemTime::now()
            .duration_since(std::time::UNIX_EPOCH)
            .unwrap()
            .as_secs();
        let expires_at = (now + expires_in_secs) as i64;

        let _ = sqlx::query(
            "INSERT INTO api_cache (key, value, expires_at) 
             VALUES (?, ?, ?)
             ON CONFLICT(key) DO UPDATE SET 
             value=excluded.value, 
             expires_at=excluded.expires_at"
        )
        .bind(key)
        .bind(value)
        .bind(expires_at)
        .execute(&self.pool)
        .await;
    }
}
