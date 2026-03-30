"""
social_publish.py - 쓰레드 & 인스타그램 자동 발행

블로그 글 발행 후 소셜 미디어에 자동으로 홍보 포스트를 게시합니다.

실행:
  python social_publish.py                     # 최근 발행 글 → 쓰레드+인스타
  python social_publish.py --threads-only      # 쓰레드만
  python social_publish.py --instagram-only    # 인스타그램만
  python social_publish.py --count 3           # 최근 3개 글 발행
  python social_publish.py --dry-run           # 테스트 (실제 발행 안함)

필요한 환경변수:
  THREADS_ACCESS_TOKEN     - Meta Threads API 토큰
  THREADS_USER_ID          - 쓰레드 사용자 ID
  INSTAGRAM_ACCESS_TOKEN   - Instagram Graph API 토큰
  INSTAGRAM_USER_ID        - 인스타그램 비즈니스 계정 ID
  ANTHROPIC_API_KEY        - Claude API (소셜 콘텐츠 생성용)
"""

import os
import sys
import json
import re
import time
import urllib.request
import urllib.parse
from datetime import datetime, timedelta, timezone
from pathlib import Path

# Windows 터미널 인코딩 대응
if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")

from dotenv import load_dotenv
load_dotenv()

# Anthropic
from anthropic import Anthropic
claude = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", ""))
CLAUDE_MODEL = "claude-sonnet-4-20250514"

# 사이트 정보
SITE_URL = os.environ.get("BLOG_SITE_URL", "https://seroai.xyz")
BLOG_DIR = Path(os.environ.get("BLOG_REPO_PATH", str(Path(__file__).parent.parent)))
POSTS_DIR = BLOG_DIR / "content" / "posts"
HISTORY_FILE = Path(__file__).parent / "social_history.json"

# API 토큰
THREADS_TOKEN = os.environ.get("THREADS_ACCESS_TOKEN", "")
THREADS_USER_ID = os.environ.get("THREADS_USER_ID", "")
INSTAGRAM_TOKEN = os.environ.get("INSTAGRAM_ACCESS_TOKEN", "")
INSTAGRAM_USER_ID = os.environ.get("INSTAGRAM_USER_ID", "")

KST = timezone(timedelta(hours=9))


# ──────────────────────────────────────────────
# 히스토리 관리
# ──────────────────────────────────────────────
def load_history() -> dict:
    if HISTORY_FILE.exists():
        return json.loads(HISTORY_FILE.read_text(encoding="utf-8"))
    return {"threads": [], "instagram": []}


def save_history(history: dict):
    HISTORY_FILE.write_text(json.dumps(history, ensure_ascii=False, indent=2), encoding="utf-8")


# ──────────────────────────────────────────────
# 최근 발행된 블로그 글 가져오기
# ──────────────────────────────────────────────
def get_recent_posts(count: int = 3) -> list[dict]:
    """최근 발행된 MDX 파일에서 메타데이터 추출"""
    posts = []
    mdx_files = sorted(POSTS_DIR.glob("*.mdx"), key=lambda f: f.stat().st_mtime, reverse=True)

    for f in mdx_files[:count * 2]:  # 여유분 확보
        content = f.read_text(encoding="utf-8")
        # frontmatter 파싱
        match = re.match(r"^---\n(.*?)\n---\n(.+)", content, re.DOTALL)
        if not match:
            continue

        fm_text = match.group(1)
        body = match.group(2)

        # 간단 YAML 파싱
        meta = {}
        for line in fm_text.split("\n"):
            m = re.match(r'^(\w+):\s*"?(.+?)"?\s*$', line)
            if m:
                meta[m.group(1)] = m.group(2).strip('"')

        if meta.get("published", "true") == "false":
            continue

        slug = f.stem
        posts.append({
            "slug": slug,
            "title": meta.get("title", ""),
            "description": meta.get("description", ""),
            "category": meta.get("category", ""),
            "tldr": meta.get("tldr", ""),
            "tags": re.findall(r'"([^"]+)"', fm_text.split("tags:")[1].split("\n")[0]) if "tags:" in fm_text else [],
            "url": f"{SITE_URL}/posts/{slug}",
            "body_preview": body[:500],
        })

        if len(posts) >= count:
            break

    return posts


# ──────────────────────────────────────────────
# Claude로 소셜 미디어 콘텐츠 생성
# ──────────────────────────────────────────────
THREADS_PROMPT = """블로그 글 정보를 바탕으로 쓰레드(Threads) 포스트를 작성해주세요.

블로그 글:
- 제목: {title}
- 요약: {description}
- TL;DR: {tldr}
- 카테고리: {category}
- URL: {url}

작성 규칙:
1. 쓰레드 최적 길이: 150~300자
2. 첫 줄에 후킹 — 질문이나 놀라운 사실로 시작
3. 핵심 인사이트 2~3개를 짧게 정리
4. 마지막에 블로그 링크 자연스럽게 포함
5. 해시태그 3~5개 (마지막 줄)
6. 이모지 적절히 사용 (2~3개)
7. 볼드(**) 마크다운 사용 금지 — 쓰레드는 마크다운 미지원
8. 자연스럽고 대화체, 광고 느낌 없이

쓰레드 포스트만 출력 (JSON 아님, 순수 텍스트):"""

INSTAGRAM_PROMPT = """블로그 글 정보를 바탕으로 인스타그램 피드 캡션을 작성해주세요.

블로그 글:
- 제목: {title}
- 요약: {description}
- TL;DR: {tldr}
- 카테고리: {category}
- URL: {url}

작성 규칙:
1. 캡션 길이: 200~400자
2. 첫 줄에 강력한 후킹 (질문 또는 통계)
3. 줄바꿈으로 가독성 확보
4. 핵심 인사이트 3~4개 나열
5. CTA(Call to Action): "자세한 내용은 프로필 링크에서"
6. 해시태그 10~15개 (마지막 섹션)
7. 이모지 적극 활용 (인스타 문화)
8. 볼드(**) 마크다운 사용 금지
9. 친근하고 정보성 톤

인스타그램 캡션만 출력 (JSON 아님, 순수 텍스트):"""


def generate_threads_post(post: dict) -> str:
    """Claude로 쓰레드 포스트 생성"""
    response = claude.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": THREADS_PROMPT.format(**post),
        }],
    )
    return response.content[0].text.strip()


def generate_instagram_caption(post: dict) -> str:
    """Claude로 인스타그램 캡션 생성"""
    response = claude.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=1024,
        messages=[{
            "role": "user",
            "content": INSTAGRAM_PROMPT.format(**post),
        }],
    )
    return response.content[0].text.strip()


# ──────────────────────────────────────────────
# Threads API
# ──────────────────────────────────────────────
def publish_to_threads(text: str, dry_run: bool = False) -> dict:
    """Threads Publishing API로 포스트 발행"""
    if not THREADS_TOKEN or not THREADS_USER_ID:
        return {"error": "THREADS_ACCESS_TOKEN 또는 THREADS_USER_ID 미설정"}

    if dry_run:
        print(f"  [DRY-RUN] 쓰레드: {text[:80]}...")
        return {"dry_run": True}

    # Step 1: 미디어 컨테이너 생성
    create_url = f"https://graph.threads.net/v1.0/{THREADS_USER_ID}/threads"
    create_data = urllib.parse.urlencode({
        "media_type": "TEXT",
        "text": text,
        "access_token": THREADS_TOKEN,
    }).encode()

    req = urllib.request.Request(create_url, data=create_data, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            creation_id = result["id"]
    except Exception as e:
        return {"error": f"컨테이너 생성 실패: {e}"}

    # Step 2: 발행 (잠시 대기 후)
    time.sleep(3)
    publish_url = f"https://graph.threads.net/v1.0/{THREADS_USER_ID}/threads_publish"
    publish_data = urllib.parse.urlencode({
        "creation_id": creation_id,
        "access_token": THREADS_TOKEN,
    }).encode()

    req = urllib.request.Request(publish_url, data=publish_data, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            print(f"  [OK] 쓰레드 발행 완료 (ID: {result.get('id', 'N/A')})")
            return result
    except Exception as e:
        return {"error": f"발행 실패: {e}"}


# ──────────────────────────────────────────────
# Instagram API
# ──────────────────────────────────────────────
def publish_to_instagram(caption: str, image_url: str = "", dry_run: bool = False) -> dict:
    """Instagram Graph API로 포스트 발행"""
    if not INSTAGRAM_TOKEN or not INSTAGRAM_USER_ID:
        return {"error": "INSTAGRAM_ACCESS_TOKEN 또는 INSTAGRAM_USER_ID 미설정"}

    if dry_run:
        print(f"  [DRY-RUN] 인스타: {caption[:80]}...")
        return {"dry_run": True}

    # 이미지 없으면 기본 OG 이미지 사용
    if not image_url:
        image_url = f"{SITE_URL}/og-default.png"

    # Step 1: 미디어 컨테이너 생성
    create_url = f"https://graph.facebook.com/v19.0/{INSTAGRAM_USER_ID}/media"
    create_data = urllib.parse.urlencode({
        "image_url": image_url,
        "caption": caption,
        "access_token": INSTAGRAM_TOKEN,
    }).encode()

    req = urllib.request.Request(create_url, data=create_data, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            creation_id = result["id"]
    except Exception as e:
        return {"error": f"컨테이너 생성 실패: {e}"}

    # Step 2: 발행
    time.sleep(5)
    publish_url = f"https://graph.facebook.com/v19.0/{INSTAGRAM_USER_ID}/media_publish"
    publish_data = urllib.parse.urlencode({
        "creation_id": creation_id,
        "access_token": INSTAGRAM_TOKEN,
    }).encode()

    req = urllib.request.Request(publish_url, data=publish_data, method="POST")
    try:
        with urllib.request.urlopen(req) as resp:
            result = json.loads(resp.read())
            print(f"  [OK] 인스타그램 발행 완료 (ID: {result.get('id', 'N/A')})")
            return result
    except Exception as e:
        return {"error": f"발행 실패: {e}"}


# ──────────────────────────────────────────────
# 메인 실행
# ──────────────────────────────────────────────
def run_social_publish(
    count: int = 3,
    threads: bool = True,
    instagram: bool = True,
    dry_run: bool = False,
):
    """블로그 글 → 소셜 미디어 자동 발행"""
    now = datetime.now(KST)
    print("=" * 60)
    print("소셜 미디어 자동 발행")
    print(f"  시각: {now.strftime('%Y-%m-%d %H:%M KST')}")
    print(f"  대상: {'쓰레드' if threads else ''} {'인스타그램' if instagram else ''}")
    print(f"  글 수: {count}개")
    print(f"  모드: {'DRY-RUN' if dry_run else 'LIVE'}")
    print("=" * 60)

    # 최근 글 가져오기
    posts = get_recent_posts(count)
    if not posts:
        print("[!] 발행할 글이 없습니다.")
        return

    # 이미 발행된 글 제외
    history = load_history()
    threads_done = set(history.get("threads", []))
    instagram_done = set(history.get("instagram", []))

    results = []

    for i, post in enumerate(posts, 1):
        print(f"\n{'─' * 50}")
        print(f"[{i}/{len(posts)}] {post['title']}")
        print(f"  URL: {post['url']}")

        # 쓰레드 발행
        if threads and post["slug"] not in threads_done:
            print("\n  [쓰레드] 콘텐츠 생성 중...")
            threads_text = generate_threads_post(post)
            print(f"  [쓰레드] 생성 완료 ({len(threads_text)}자)")
            print(f"  ──────\n  {threads_text}\n  ──────")

            result = publish_to_threads(threads_text, dry_run)
            if "error" not in result:
                history.setdefault("threads", []).append(post["slug"])
                results.append({"platform": "threads", "slug": post["slug"], "status": "ok"})
            else:
                print(f"  [!] 쓰레드 오류: {result['error']}")
                results.append({"platform": "threads", "slug": post["slug"], "status": "error", "msg": result["error"]})
        elif threads:
            print("  [쓰레드] 이미 발행됨, 스킵")

        # 인스타그램 발행
        if instagram and post["slug"] not in instagram_done:
            print("\n  [인스타그램] 캡션 생성 중...")
            ig_caption = generate_instagram_caption(post)
            print(f"  [인스타그램] 생성 완료 ({len(ig_caption)}자)")
            print(f"  ──────\n  {ig_caption}\n  ──────")

            result = publish_to_instagram(ig_caption, dry_run=dry_run)
            if "error" not in result:
                history.setdefault("instagram", []).append(post["slug"])
                results.append({"platform": "instagram", "slug": post["slug"], "status": "ok"})
            else:
                print(f"  [!] 인스타그램 오류: {result['error']}")
                results.append({"platform": "instagram", "slug": post["slug"], "status": "error", "msg": result["error"]})
        elif instagram:
            print("  [인스타그램] 이미 발행됨, 스킵")

        time.sleep(2)  # API 레이트 리밋 대응

    # 히스토리 저장
    save_history(history)

    # 결과 요약
    ok_count = sum(1 for r in results if r["status"] == "ok")
    err_count = sum(1 for r in results if r["status"] == "error")
    print(f"\n{'=' * 60}")
    print(f"완료! 성공: {ok_count}건, 실패: {err_count}건")
    print("=" * 60)


# ──────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────
if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="소셜 미디어 자동 발행")
    parser.add_argument("--count", type=int, default=3, help="발행할 글 수")
    parser.add_argument("--threads-only", action="store_true", help="쓰레드만 발행")
    parser.add_argument("--instagram-only", action="store_true", help="인스타그램만 발행")
    parser.add_argument("--dry-run", action="store_true", help="테스트 모드")
    args = parser.parse_args()

    do_threads = not args.instagram_only
    do_instagram = not args.threads_only

    run_social_publish(
        count=args.count,
        threads=do_threads,
        instagram=do_instagram,
        dry_run=args.dry_run,
    )
