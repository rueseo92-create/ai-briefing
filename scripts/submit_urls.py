"""
submit_urls.py - 검색엔진에 URL 제출 (IndexNow + Google ping)

사용법:
  python submit_urls.py                    # 모든 URL 제출
  python submit_urls.py --new-only         # 오늘 생성된 URL만
  python submit_urls.py --url https://...  # 특정 URL만
"""

import json
import urllib.request
import urllib.parse
from pathlib import Path
from datetime import datetime

import os
from dotenv import load_dotenv
load_dotenv()
SITE_URL = os.environ.get("BLOG_SITE_URL", "https://seroai.xyz")
INDEXNOW_KEY = "d5566bb4311e4891bf4f30754b0d87d6"

POSTS_DIR = Path(__file__).parent.parent / "content" / "posts"


def get_all_post_urls() -> list[str]:
    """모든 포스트 URL 목록"""
    urls = [SITE_URL]
    if POSTS_DIR.exists():
        for f in sorted(POSTS_DIR.glob("*.mdx")):
            slug = f.stem
            urls.append(f"{SITE_URL}/posts/{slug}")
    return urls


def get_today_urls() -> list[str]:
    """오늘 생성된 포스트 URL만"""
    today = datetime.now().strftime("%Y-%m-%d")
    urls = []
    if POSTS_DIR.exists():
        for f in POSTS_DIR.glob(f"{today}*.mdx"):
            slug = f.stem
            urls.append(f"{SITE_URL}/posts/{slug}")
    return urls


def submit_indexnow(urls: list[str]) -> bool:
    """IndexNow API로 Bing/Yandex에 URL 제출"""
    if not urls:
        print("[IndexNow] 제출할 URL 없음")
        return False

    print(f"[IndexNow] {len(urls)}개 URL 제출 중...")

    payload = json.dumps({
        "host": SITE_URL.replace("https://", ""),
        "key": INDEXNOW_KEY,
        "keyLocation": f"{SITE_URL}/{INDEXNOW_KEY}.txt",
        "urlList": urls[:10000],
    }).encode("utf-8")

    # Bing IndexNow
    for engine in ["www.bing.com", "yandex.com"]:
        try:
            req = urllib.request.Request(
                f"https://{engine}/indexnow",
                data=payload,
                headers={"Content-Type": "application/json"},
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=15) as resp:
                status = resp.status
                print(f"  → {engine}: HTTP {status} OK")
        except Exception as e:
            print(f"  → {engine}: 실패 ({e})")

    return True


def submit_google_sitemap():
    """Google에 sitemap 알림 (ping deprecated → GSC 안내)"""
    sitemap_url = f"{SITE_URL}/sitemap.xml"
    print(f"[Google] Sitemap: {sitemap_url}")
    print("  → Google ping API는 2023년 deprecated됨")
    print("  → Google Search Console에서 sitemap 직접 제출 필요:")
    print("  → https://search.google.com/search-console")
    print("  → sitemap.xml은 자동 생성되므로 GSC 등록만 하면 자동 색인됨")


def submit_naver_sitemap():
    """네이버에 sitemap 알림"""
    print("[네이버] 네이버 서치어드바이저에서 직접 등록 필요:")
    print("  → https://searchadvisor.naver.com/console/board")
    print(f"  → 사이트 URL: {SITE_URL}")
    print(f"  → Sitemap URL: {SITE_URL}/sitemap.xml")


def main():
    import argparse
    parser = argparse.ArgumentParser(description="검색엔진 URL 제출")
    parser.add_argument("--new-only", action="store_true", help="오늘 생성된 URL만")
    parser.add_argument("--url", type=str, help="특정 URL만 제출")
    args = parser.parse_args()

    print("=" * 50)
    print("검색엔진 URL 제출")
    print(f"시각: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    print("=" * 50)

    if args.url:
        urls = [args.url]
    elif args.new_only:
        urls = get_today_urls()
    else:
        urls = get_all_post_urls()

    print(f"\n제출 대상: {len(urls)}개 URL")
    for u in urls[:5]:
        print(f"  - {u}")
    if len(urls) > 5:
        print(f"  ... 외 {len(urls)-5}개")

    print()
    submit_indexnow(urls)
    print()
    submit_google_sitemap()
    print()
    submit_naver_sitemap()

    print("\n" + "=" * 50)
    print("완료! 색인 반영까지 소요 시간:")
    print("  Bing/Yandex (IndexNow): 수 시간 ~ 1일")
    print("  Google: GSC 등록 후 1~3일")
    print("  네이버: 서치어드바이저 등록 후 1~7일")
    print("=" * 50)


if __name__ == "__main__":
    main()
