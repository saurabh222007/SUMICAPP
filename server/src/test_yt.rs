use ytmusicapi::YTMusic;

#[tokio::main]
async fn main() {
    let yt = YTMusic::new().await.unwrap();
    let res = yt.search("arijit singh", None).await.unwrap();
    println!("{:?}", res);
}
