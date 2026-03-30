"""
community_seed.py - 커뮤니티 시딩 콘텐츠 자동 생성

블로그 글을 커뮤니티 플랫폼별 최적화 포맷으로 변환합니다.
직접 발행이 아닌, 복사-붙여넣기용 콘텐츠를 생성합니다.

실행:
  python community_seed.py                      # 최근 3개 글 → 모든 플랫폼
  python community_seed.py --count 5            # 최근 5개 글
  python community_seed.py --platform geeknews  # 긱뉴스용만
  python community_seed.py --slug 2026-03-30-xxx  # 특정 글만

출력:
  scripts/community_seeds/ 폴더에 마크다운 파일 생성
  → 각 파일을 열어 해당 커뮤니티에 복사-붙여넣기

필요한 환경변수:
  ANTHROPIC_API_KEY - Claude API
"""

import os
import sys
import io
import json
import re
from datetime import datetime, timedelta, timezone
from pathlib import Path

if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

from dotenv import load_dotenv
load_dotenv()

from anthropic import Anthropic

claude = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", ""))
CLAUDE_MODEL = "claude-sonnet-4-20250514"

SITE_URL = os.environ.get("BLOG_SITE_URL", "https://seroai.xyz")
BLOG_DIR = Path(os.environ.get("BLOG_REPO_PATH", str(Path(__file__).parent.parent)))
POSTS_DIR = BLOG_DIR / "content" / "posts"
OUTPUT_DIR = Path(__file__).parent / "community_seeds"
KST = timezone(timedelta(hours=9))

# ──────────────────────────────────────────────
# 플랫폼별 프롬프트
# ──────────────────────────────────────────────
PLATFORMS = {
    "geeknews": {
        "name": "GeekNews (긱뉴스)",
        "prompt": """블로그 글을 GeekNews(긱뉴스) 게시용으로 변환해주세요.

블로그 글:
- 제목: {title}
- 요약: {description}
- 본문 미리보기: {body_preview}
- URL: {url}

작성 규칙:
1. 제목: 기술적이고 흥미를 끌되 과장 없이 (40자 이내)
2. 본문: 핵심 내용을 2~3문단으로 요약
3. "왜 중요한가" 관점 포함
4. 기술적 인사이트 위주 (마케팅 느낌 배제)
5. 마지막에 원문 링크
6. 긱뉴스 톤: 개발자/기술 관심자 대상, 담백하고 정보 위주

출력 형식:
---
제목: (여기에 제목)
---
(여기에 본문)
""",
    },
    "reddit": {
        "name": "Reddit (r/artificial, r/ChatGPT)",
        "prompt": """Convert this blog post into a Reddit-friendly post for r/artificial or r/ChatGPT.

Blog post:
- Title: {title}
- Description: {description}
- Body preview: {body_preview}
- URL: {url}

Rules:
1. Title: Engaging but not clickbait, informative (English)
2. Body: 2~3 paragraphs summarizing key insights
3. Include "Why this matters" angle
4. End with a discussion question to encourage comments
5. Add source link naturally
6. Reddit tone: conversational, informative, no self-promotion feel
7. Write in English

Output format:
---
Title: (title here)
Subreddit: (suggested subreddit)
---
(body here)
""",
    },
    "naver_cafe": {
        "name": "네이버 카페 (AI/블로그/마케팅)",
        "prompt": """블로그 글을 네이버 카페 게시용으로 변환해주세요.

블로그 글:
- 제목: {title}
- 요약: {description}
- 본문 미리보기: {body_preview}
- URL: {url}

작성 규칙:
1. 제목: 네이버 카페 스타일 (질문형 또는 정보 공유형, 40자 이내)
2. 본문 시작: 인사 + 간단한 자기소개 (AI 블로거)
3. 핵심 내용 3~4개 불릿으로 정리
4. "도움이 되셨으면 좋겠습니다" 식 마무리
5. 원문 링크는 "더 자세한 내용은 여기서" 형태로
6. 네이버 카페 톤: 친근하고 정중한 한국어, 존댓말
7. 이모지 1~2개만 (과하지 않게)

출력 형식:
---
제목: (여기에 제목)
추천 카페: (AI, 블로그, 마케팅 중 적합한 카테고리)
---
(여기에 본문)
""",
    },
    "x_twitter": {
        "name": "X (Twitter)",
        "prompt": """블로그 글을 X(트위터) 스레드용으로 변환해주세요.

블로그 글:
- 제목: {title}
- 요약: {description}
- 본문 미리보기: {body_preview}
- URL: {url}

작성 규칙:
1. 첫 트윗: 강력한 후킹 (놀라운 사실 또는 질문, 280자 이내)
2. 2~4번 트윗: 핵심 인사이트 (각 280자 이내)
3. 마지막 트윗: CTA + 블로그 링크
4. 각 트윗은 "---" 로 구분
5. 한국어 작성
6. 이모지 적절히 활용
7. 해시태그 2~3개 (마지막 트윗에만)

출력 형식:
[1/N]
(첫 트윗)

---

[2/N]
(두번째 트윗)

---
...
""",
    },
}


# ──────────────────────────────────────────────
# 블로그 글 파싱
# ──────────────────────────────────────────────
def get_recent_posts(count: int = 3, slug_filter: str = "") -> list[dict]:
    posts = []
    mdx_files = sorted(POSTS_DIR.glob("*.mdx"), key=lambda f: f.stat().st_mtime, reverse=True)

    for f in mdx_files[:count * 3]:
        if slug_filter and slug_filter not in f.stem:
            continue

        content = f.read_text(encoding="utf-8")
        match = re.match(r"^---\n(.*?)\n---\n(.+)", content, re.DOTALL)
        if not match:
            continue

        fm_text = match.group(1)
        body = match.group(2)

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
            "url": f"{SITE_URL}/posts/{slug}",
            "body_preview": body[:800],
        })

        if slug_filter:
            break
        if len(posts) >= count:
            break

    return posts


# ──────────────────────────────────────────────
# Claude로 커뮤니티 콘텐츠 생성
# ──────────────────────────────────────────────
def generate_community_content(post: dict, platform_key: str) -> str:
    platform = PLATFORMS[platform_key]
    prompt = platform["prompt"].format(**post)

    response = claude.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=1500,
        messages=[{"role": "user", "content": prompt}],
    )
    return response.content[0].text.strip()


# ──────────────────────────────────────────────
# 출력 저장
# ──────────────────────────────────────────────
def save_seed(slug: str, platform_key: str, content: str):
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    date_str = datetime.now(KST).strftime("%Y%m%d")
    filename = f"{date_str}_{slug}_{platform_key}.md"
    filepath = OUTPUT_DIR / filename

    header = f"# {PLATFORMS[platform_key]['name']} 시딩 콘텐츠\n"
    header += f"# 원문: {SITE_URL}/posts/{slug}\n"
    header += f"# 생성일: {datetime.now(KST).strftime('%Y-%m-%d %H:%M KST')}\n\n"

    filepath.write_text(header + content, encoding="utf-8")
    return filepath


# ──────────────────────────────────────────────
# 메인
# ──────────────────────────────────────────────
def run(count: int = 3, platform: str = "all", slug: str = ""):
    now = datetime.now(KST)
    print("=" * 60)
    print("커뮤니티 시딩 콘텐츠 생성")
    print(f"  시각: {now.strftime('%Y-%m-%d %H:%M KST')}")
    print(f"  플랫폼: {platform}")
    print(f"  글 수: {count}개")
    print("=" * 60)

    posts = get_recent_posts(count, slug)
    if not posts:
        print("[!] 대상 글이 없습니다.")
        return

    platforms_to_run = list(PLATFORMS.keys()) if platform == "all" else [platform]
    generated = []

    for post in posts:
        print(f"\n{'─' * 50}")
        print(f"[글] {post['title']}")

        for pkey in platforms_to_run:
            pname = PLATFORMS[pkey]["name"]
            print(f"\n  [{pname}] 생성 중...")

            content = generate_community_content(post, pkey)
            filepath = save_seed(post["slug"], pkey, content)

            print(f"  [{pname}] 저장 완료 → {filepath.name}")
            generated.append(filepath)

    print(f"\n{'=' * 60}")
    print(f"완료! 총 {len(generated)}개 시딩 콘텐츠 생성")
    print(f"저장 위치: {OUTPUT_DIR}")
    print("\n각 파일을 열어 해당 커뮤니티에 복사-붙여넣기하세요.")
    print("=" * 60)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="커뮤니티 시딩 콘텐츠 생성")
    parser.add_argument("--count", type=int, default=3, help="대상 글 수")
    parser.add_argument("--platform", choices=list(PLATFORMS.keys()) + ["all"], default="all", help="플랫폼")
    parser.add_argument("--slug", default="", help="특정 글 slug")
    args = parser.parse_args()

    run(count=args.count, platform=args.platform, slug=args.slug)
