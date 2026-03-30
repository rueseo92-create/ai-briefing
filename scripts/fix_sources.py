"""
fix_sources.py - 가짜 출처 URL을 공식 도메인으로 교체

모든 MDX 파일의 sources URL을 검증하고, 지어낸 경로를
해당 기관의 공식 메인 페이지로 교체합니다.
"""

import os
import sys
import io
import re
from pathlib import Path

if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

POSTS_DIR = Path(os.environ.get("BLOG_REPO_PATH", str(Path(__file__).parent.parent))) / "content" / "posts"

# 도메인 → 공식 메인 URL 매핑
DOMAIN_CLEANUP = {
    "openai.com": "https://openai.com",
    "platform.openai.com": "https://platform.openai.com/docs",
    "research.openai.com": "https://openai.com/research",
    "www.anthropic.com": "https://www.anthropic.com",
    "anthropic.com": "https://www.anthropic.com",
    "developers.google.com": None,  # 구글 개발자 문서는 대부분 실제 경로
    "support.google.com": None,
    "blog.google": None,
    "searchadvisor.naver.com": None,
    "schema.org": None,
    "nextjs.org": None,
    "llmstxt.org": None,
    "arxiv.org": None,
    "docs.perplexity.ai": None,
    "zapier.com": "https://zapier.com",
    "github.blog": "https://github.blog",
    "survey.stackoverflow.com": "https://survey.stackoverflow.co",
    "techcrunch.com": "https://techcrunch.com",
    "www.msit.go.kr": "https://www.msit.go.kr",
    "msit.go.kr": "https://www.msit.go.kr",
    "kisa.or.kr": "https://www.kisa.or.kr",
    "privacy.go.kr": "https://www.privacy.go.kr",
    "www.copyright.go.kr": "https://www.copyright.go.kr",
    "www.ncloud.com": "https://www.ncloud.com",
    "kiise.or.kr": "https://www.kiise.or.kr",
    "www.tta.or.kr": "https://www.tta.or.kr",
    "blog.naver.com": "https://blog.naver.com",
    "www.lge.co.kr": "https://www.lge.co.kr",
    "news.samsung.com": "https://news.samsung.com/kr",
}

# 무조건 가짜인 도메인 (삭제)
FAKE_DOMAINS = {
    "marketingresearch.co.kr",
    "www.bloggersurvey.co.kr",
    "www.koreaai.or.kr",
    "www.tech-research.org",
    "www.digital-trends.co.kr",
    "kma.or.kr",
    "dmri.kr",
    "kdm.ac.kr",
    "www.dt.co.kr",
    "www.ai-manufacturing.go.kr",
    "www.modoo.or.kr",
}


def extract_domain(url: str) -> str:
    match = re.match(r'https?://([^/]+)', url)
    return match.group(1) if match else ""


def is_suspicious_path(url: str) -> bool:
    """너무 구체적인 가짜 경로 감지"""
    patterns = [
        r'202[0-9].*report',
        r'202[0-9].*guide',
        r'202[0-9].*survey',
        r'ai-\w+-202[0-9]',
        r'new-regulations-202[0-9]',
        r'conference/202[0-9]',
        r'contents/202[0-9]',
        r'/report/202[0-9]',
        r'/reports/202[0-9]',
        r'/research/.*202[0-9]',
        r'blog/.*202[0-9].*(?:update|launch|workflow)',
    ]
    for p in patterns:
        if re.search(p, url, re.IGNORECASE):
            return True
    return False


def fix_source_url(url: str) -> str | None:
    """URL을 검증하고 수정. None이면 삭제"""
    domain = extract_domain(url)

    # 가짜 도메인이면 삭제
    if domain in FAKE_DOMAINS:
        return None

    # 알려진 도메인 + 의심스러운 경로면 메인으로 교체
    if domain in DOMAIN_CLEANUP:
        replacement = DOMAIN_CLEANUP[domain]
        if replacement is None:
            # 화이트리스트 도메인 — 경로도 OK일 수 있음
            if is_suspicious_path(url):
                # 경로만 잘라서 메인 도메인으로
                return f"https://{domain}"
            return url

        if is_suspicious_path(url):
            return replacement
        return url

    # 모르는 도메인 + 의심스러운 경로면 삭제
    if is_suspicious_path(url):
        return None

    return url


def fix_file(filepath: Path) -> int:
    """파일의 소스 URL 수정. 변경 수 반환"""
    content = filepath.read_text(encoding="utf-8")
    original = content
    changes = 0

    # frontmatter의 sources url 수정
    def replace_url(match):
        nonlocal changes
        prefix = match.group(1)
        url = match.group(2)
        fixed = fix_source_url(url)
        if fixed is None:
            changes += 1
            return f'{prefix}""'  # URL 비우기
        if fixed != url:
            changes += 1
            return f'{prefix}"{fixed}"'
        return match.group(0)

    content = re.sub(
        r'(url:\s*)"(https?://[^"]+)"',
        replace_url,
        content,
    )

    if content != original:
        filepath.write_text(content, encoding="utf-8")

    return changes


def main():
    print("=" * 60)
    print("소스 URL 검증 및 수정")
    print("=" * 60)

    total_changes = 0

    # 메인 포스트
    for f in sorted(POSTS_DIR.glob("*.mdx")):
        changes = fix_file(f)
        if changes:
            print(f"  [수정 {changes}건] {f.name}")
            total_changes += changes

    # 번역본
    for lang_dir in ["en", "ja", "zh", "es"]:
        lang_path = POSTS_DIR / lang_dir
        if not lang_path.exists():
            continue
        for f in sorted(lang_path.glob("*.mdx")):
            changes = fix_file(f)
            if changes:
                print(f"  [수정 {changes}건] {lang_dir}/{f.name}")
                total_changes += changes

    print(f"\n총 {total_changes}건 URL 수정 완료")


if __name__ == "__main__":
    main()
