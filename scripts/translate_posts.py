"""
translate_posts.py - 한국어 MDX 글을 4개 언어로 번역

사용법:
  python translate_posts.py                      # 번역 없는 글 모두 번역
  python translate_posts.py --slug ai-prompt      # 특정 슬러그만
  python translate_posts.py --dry-run              # 실제 번역 없이 대상만 확인
"""

import os
import sys
import io
import re
import argparse
from pathlib import Path

if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

from dotenv import load_dotenv

load_dotenv()
load_dotenv(Path(__file__).parent / ".env")

import anthropic

CLAUDE_MODEL = "claude-sonnet-4-20250514"
POSTS_DIR = Path(os.environ.get("BLOG_REPO_PATH", str(Path(__file__).parent.parent))) / "content" / "posts"
LANGUAGES = {
    "en": "English",
}

client = anthropic.Anthropic()


def find_missing_translations() -> list[tuple[Path, str]]:
    """번역이 없는 (한국어 파일, 언어코드) 쌍 반환"""
    missing = []
    for ko_file in sorted(POSTS_DIR.glob("*.mdx")):
        for lang in LANGUAGES:
            lang_file = POSTS_DIR / lang / ko_file.name
            if not lang_file.exists():
                missing.append((ko_file, lang))
    return missing


def translate_post(ko_file: Path, lang: str) -> str:
    """한국어 MDX → 번역된 MDX 문자열 반환"""
    content = ko_file.read_text(encoding="utf-8")
    lang_name = LANGUAGES[lang]

    prompt = f"""Translate this Korean MDX blog post to {lang_name}.

Rules:
- Translate title, description, tldr, and all body text
- Keep frontmatter YAML structure exactly the same (field names stay in English)
- Keep tags in their original Korean form (do NOT translate tags)
- Keep all URLs, code blocks, and MDX syntax unchanged
- Keep source names in their original form
- Maintain the same markdown heading structure
- Output ONLY the translated MDX content, nothing else
- Do NOT wrap in code fences

Korean MDX:
{content}"""

    response = client.messages.create(
        model=CLAUDE_MODEL,
        max_tokens=16384,
        messages=[{"role": "user", "content": prompt}],
    )
    return response.content[0].text.strip()


def main():
    parser = argparse.ArgumentParser(description="한국어 MDX 글 → 다국어 번역")
    parser.add_argument("--slug", help="특정 슬러그만 번역 (부분 매칭)")
    parser.add_argument("--lang", help="특정 언어만 (en/ja/zh/es)")
    parser.add_argument("--dry-run", action="store_true", help="대상만 확인")
    args = parser.parse_args()

    missing = find_missing_translations()

    if args.slug:
        missing = [(f, l) for f, l in missing if args.slug in f.stem]
    if args.lang:
        missing = [(f, l) for f, l in missing if l == args.lang]

    print(f"번역 대상: {len(missing)}건")
    if not missing:
        print("모든 번역이 완료되어 있습니다.")
        return

    for ko_file, lang in missing:
        print(f"  - {ko_file.name} → {lang}/")

    if args.dry_run:
        return

    success = 0
    fail = 0
    for ko_file, lang in missing:
        lang_dir = POSTS_DIR / lang
        lang_dir.mkdir(exist_ok=True)
        out_path = lang_dir / ko_file.name

        print(f"\n[번역중] {ko_file.name} → {lang}/ ...", end=" ", flush=True)
        try:
            translated = translate_post(ko_file, lang)
            # 코드 펜스 제거 (혹시 있다면)
            if translated.startswith("```"):
                translated = re.sub(r'^```\w*\n', '', translated)
                translated = re.sub(r'\n```$', '', translated)

            out_path.write_text(translated, encoding="utf-8")
            print("완료")
            success += 1
        except Exception as e:
            print(f"실패: {e}")
            fail += 1

    print(f"\n번역 완료: 성공 {success}건, 실패 {fail}건")


if __name__ == "__main__":
    main()
