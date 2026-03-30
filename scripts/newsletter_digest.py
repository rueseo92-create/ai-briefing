"""
newsletter_digest.py - 주간 뉴스레터 다이제스트 자동 생성

최근 1주일 블로그 글을 분석하여 뉴스레터용 HTML 이메일을 생성합니다.
구독자 목록은 data/subscribers.json에서 읽어옵니다.

실행:
  python newsletter_digest.py                    # 이번 주 다이제스트 생성
  python newsletter_digest.py --send             # 생성 + 발송 (Resend API)
  python newsletter_digest.py --preview          # HTML 미리보기 파일 생성
  python newsletter_digest.py --days 14          # 최근 14일 기준

출력:
  scripts/newsletters/ 폴더에 HTML 파일 생성

필요한 환경변수:
  ANTHROPIC_API_KEY   - Claude API
  RESEND_API_KEY      - Resend API (발송 시)
  NEWSLETTER_FROM     - 발신 이메일 (기본: newsletter@seroai.xyz)
"""

import os
import sys
import io
import json
import re
import urllib.request
import urllib.parse
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
SUBSCRIBERS_FILE = BLOG_DIR / "data" / "subscribers.json"
OUTPUT_DIR = Path(__file__).parent / "newsletters"
KST = timezone(timedelta(hours=9))

RESEND_API_KEY = os.environ.get("RESEND_API_KEY", "")
NEWSLETTER_FROM = os.environ.get("NEWSLETTER_FROM", "AI Briefing <newsletter@seroai.xyz>")

CATEGORY_LABELS = {
    "ai-news": "AI 뉴스",
    "gov-projects": "정부사업",
    "ai-tools": "AI 도구",
    "tutorials": "튜토리얼",
    "marketing": "마케팅",
    "business": "비즈니스",
}


# ──────────────────────────────────────────────
# 최근 글 수집
# ──────────────────────────────────────────────
def get_posts_since(days: int = 7) -> list[dict]:
    cutoff = datetime.now(KST) - timedelta(days=days)
    posts = []

    for f in sorted(POSTS_DIR.glob("*.mdx"), key=lambda f: f.stat().st_mtime, reverse=True):
        mtime = datetime.fromtimestamp(f.stat().st_mtime, tz=KST)
        if mtime < cutoff:
            break

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
            "date": meta.get("date", mtime.strftime("%Y-%m-%d")),
            "url": f"{SITE_URL}/posts/{slug}",
        })

    return posts


# ──────────────────────────────────────────────
# Claude로 다이제스트 본문 생성
# ──────────────────────────────────────────────
def generate_digest_content(posts: list[dict]) -> dict:
    posts_summary = "\n".join(
        f"- [{p['title']}]({p['url']}) (카테고리: {CATEGORY_LABELS.get(p['category'], p['category'])})\n  설명: {p['description']}"
        for p in posts
    )

    prompt = f"""이번 주 AI 브리핑 블로그에 발행된 글 목록입니다. 뉴스레터 콘텐츠를 작성해주세요.

발행된 글:
{posts_summary}

작성 규칙:
1. 인사말: 짧고 친근하게 (1~2줄)
2. "이번 주 핵심 Pick" — 가장 중요한 글 1~2개를 하이라이트 (각 2~3줄 설명)
3. "전체 목록" — 나머지 글을 카테고리별로 정리 (제목 + 한 줄 설명)
4. 마무리: 다음 주 예고 + 블로그 방문 유도
5. 한국어 작성
6. HTML 태그 사용 금지 — 순수 텍스트만 (HTML 변환은 별도 처리)
7. 이모지 적절히 활용

다음 JSON 형식으로 출력:
{{
  "subject": "이메일 제목 (30자 이내)",
  "preview_text": "미리보기 텍스트 (50자 이내)",
  "body": "본문 전체"
}}"""

    response = claude.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=2000,
        messages=[{"role": "user", "content": prompt}],
    )

    text = response.content[0].text.strip()
    # JSON 추출
    json_match = re.search(r'\{[\s\S]*\}', text)
    if json_match:
        return json.loads(json_match.group())

    return {
        "subject": f"AI 브리핑 주간 다이제스트 — {len(posts)}개 새 글",
        "preview_text": "이번 주 AI 뉴스와 가이드를 확인하세요",
        "body": text,
    }


# ──────────────────────────────────────────────
# HTML 이메일 템플릿
# ──────────────────────────────────────────────
def build_html_email(digest: dict, posts: list[dict]) -> str:
    body_html = digest["body"].replace("\n\n", "</p><p>").replace("\n", "<br>")
    body_html = f"<p>{body_html}</p>"

    # 링크 변환: [text](url) → <a>
    body_html = re.sub(
        r'\[([^\]]+)\]\(([^)]+)\)',
        r'<a href="\2" style="color:#2563eb;text-decoration:underline">\1</a>',
        body_html,
    )

    posts_html = ""
    for p in posts[:10]:
        cat = CATEGORY_LABELS.get(p["category"], p["category"])
        posts_html += f'''
        <tr>
          <td style="padding:12px 16px;border-bottom:1px solid #f1f5f9">
            <a href="{p['url']}" style="color:#1e293b;text-decoration:none;font-weight:600;font-size:15px">{p['title']}</a>
            <br><span style="color:#64748b;font-size:13px">{cat} · {p['date']}</span>
          </td>
        </tr>'''

    now = datetime.now(KST)
    week_label = f"{(now - timedelta(days=7)).strftime('%m/%d')} ~ {now.strftime('%m/%d')}"

    return f"""<!DOCTYPE html>
<html lang="ko">
<head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f8fafc;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,sans-serif">
  <div style="max-width:600px;margin:0 auto;background:#fff">
    <!-- Header -->
    <div style="background:linear-gradient(135deg,#1e293b,#334155);padding:32px 24px;text-align:center">
      <h1 style="color:#fff;margin:0;font-size:24px">AI Briefing</h1>
      <p style="color:#94a3b8;margin:8px 0 0;font-size:14px">주간 다이제스트 · {week_label}</p>
    </div>

    <!-- Body -->
    <div style="padding:24px;color:#334155;font-size:15px;line-height:1.7">
      {body_html}
    </div>

    <!-- Post List -->
    <div style="padding:0 24px 24px">
      <h2 style="font-size:18px;color:#1e293b;border-bottom:2px solid #e2e8f0;padding-bottom:8px">이번 주 전체 글</h2>
      <table style="width:100%;border-collapse:collapse">
        {posts_html}
      </table>
    </div>

    <!-- CTA -->
    <div style="padding:24px;text-align:center">
      <a href="{SITE_URL}" style="display:inline-block;background:#2563eb;color:#fff;padding:12px 32px;border-radius:8px;text-decoration:none;font-weight:600">블로그 방문하기</a>
    </div>

    <!-- Footer -->
    <div style="background:#f8fafc;padding:24px;text-align:center;font-size:12px;color:#94a3b8">
      <p>AI 브리핑 뉴스레터 · <a href="{SITE_URL}" style="color:#64748b">seroai.xyz</a></p>
      <p>더 이상 받고 싶지 않으시면 <a href="{SITE_URL}/unsubscribe" style="color:#64748b">구독 해지</a></p>
    </div>
  </div>
</body>
</html>"""


# ──────────────────────────────────────────────
# 구독자 목록
# ──────────────────────────────────────────────
def get_subscribers() -> list[dict]:
    if not SUBSCRIBERS_FILE.exists():
        return []
    data = json.loads(SUBSCRIBERS_FILE.read_text(encoding="utf-8"))
    return [s for s in data if s.get("status", "active") == "active"]


# ──────────────────────────────────────────────
# Resend API로 발송
# ──────────────────────────────────────────────
def send_via_resend(to_email: str, subject: str, html: str) -> dict:
    if not RESEND_API_KEY:
        return {"error": "RESEND_API_KEY 미설정"}

    data = json.dumps({
        "from": NEWSLETTER_FROM,
        "to": [to_email],
        "subject": subject,
        "html": html,
    }).encode()

    req = urllib.request.Request(
        "https://api.resend.com/emails",
        data=data,
        headers={
            "Authorization": f"Bearer {RESEND_API_KEY}",
            "Content-Type": "application/json",
        },
        method="POST",
    )

    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except Exception as e:
        return {"error": str(e)}


# ──────────────────────────────────────────────
# 메인
# ──────────────────────────────────────────────
def run(days: int = 7, send: bool = False, preview: bool = False):
    now = datetime.now(KST)
    print("=" * 60)
    print("뉴스레터 다이제스트 생성")
    print(f"  시각: {now.strftime('%Y-%m-%d %H:%M KST')}")
    print(f"  기간: 최근 {days}일")
    print(f"  모드: {'발송' if send else '미리보기' if preview else '생성만'}")
    print("=" * 60)

    # 1) 최근 글 수집
    posts = get_posts_since(days)
    if not posts:
        print("[!] 해당 기간에 발행된 글이 없습니다.")
        return

    print(f"\n[1] {len(posts)}개 글 수집 완료")
    for p in posts[:5]:
        print(f"  - {p['title']}")
    if len(posts) > 5:
        print(f"  ... 외 {len(posts) - 5}개")

    # 2) Claude로 다이제스트 생성
    print("\n[2] 다이제스트 콘텐츠 생성 중...")
    digest = generate_digest_content(posts)
    print(f"  제목: {digest['subject']}")
    print(f"  미리보기: {digest['preview_text']}")

    # 3) HTML 빌드
    print("\n[3] HTML 이메일 빌드...")
    html = build_html_email(digest, posts)

    # 4) 파일 저장
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    date_str = now.strftime("%Y%m%d")
    html_path = OUTPUT_DIR / f"digest_{date_str}.html"
    html_path.write_text(html, encoding="utf-8")
    print(f"  저장: {html_path}")

    # JSON도 저장 (기록용)
    meta_path = OUTPUT_DIR / f"digest_{date_str}.json"
    meta_path.write_text(json.dumps({
        "date": now.isoformat(),
        "subject": digest["subject"],
        "preview_text": digest["preview_text"],
        "post_count": len(posts),
        "posts": [p["slug"] for p in posts],
    }, ensure_ascii=False, indent=2), encoding="utf-8")

    if preview:
        print(f"\n[미리보기] 브라우저에서 열기: {html_path}")
        return

    # 5) 발송
    if send:
        subscribers = get_subscribers()
        if not subscribers:
            print("\n[!] 구독자가 없습니다. data/subscribers.json을 확인하세요.")
            return

        print(f"\n[4] {len(subscribers)}명에게 발송 중...")
        success = 0
        for sub in subscribers:
            email = sub.get("email", "")
            if not email:
                continue
            result = send_via_resend(email, digest["subject"], html)
            if "error" in result:
                print(f"  [X] {email}: {result['error']}")
            else:
                print(f"  [OK] {email}")
                success += 1

        print(f"\n발송 완료: {success}/{len(subscribers)}명 성공")
    else:
        subscribers = get_subscribers()
        print(f"\n[INFO] 구독자 {len(subscribers)}명 대기 중")
        print("[INFO] --send 옵션으로 실제 발송 가능")

    print(f"\n{'=' * 60}")
    print("완료!")
    print("=" * 60)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="주간 뉴스레터 다이제스트")
    parser.add_argument("--days", type=int, default=7, help="기간 (일)")
    parser.add_argument("--send", action="store_true", help="실제 발송")
    parser.add_argument("--preview", action="store_true", help="HTML 미리보기만")
    args = parser.parse_args()

    run(days=args.days, send=args.send, preview=args.preview)
