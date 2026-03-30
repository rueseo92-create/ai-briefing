"""
fix_truncated.py - 잘린 블로그 글 자동 복구

잘린(truncated) MDX 파일을 감지하고 Claude API로 나머지 부분을 완성합니다.

실행:
  python fix_truncated.py                  # 잘린 글 감지 + 복구
  python fix_truncated.py --dry-run        # 감지만 (수정 안함)
  python fix_truncated.py --slug xxx       # 특정 글만 복구
  python fix_truncated.py --lang all       # 번역본도 함께 복구
"""

import os
import sys
import io
import re
import json
from pathlib import Path
from datetime import datetime

if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

from dotenv import load_dotenv
load_dotenv()

from anthropic import Anthropic

claude = Anthropic(api_key=os.environ.get("ANTHROPIC_API_KEY", ""))
CLAUDE_MODEL = "claude-sonnet-4-20250514"

BLOG_DIR = Path(os.environ.get("BLOG_REPO_PATH", str(Path(__file__).parent.parent)))
POSTS_DIR = BLOG_DIR / "content" / "posts"

# 한국어 문장 종결 패턴
KO_ENDINGS = re.compile(r'[.다요죠세습까!?\n\)`\*"]$')
# 영어 문장 종결 패턴
EN_ENDINGS = re.compile(r'[.!?\n\)`\*"]$')
# 일/중/스페인어도 유사
JA_ENDINGS = re.compile(r'[.。!？\n\)`す。た]$')
ZH_ENDINGS = re.compile(r'[.。!？\n\)`]$')


def detect_truncated(filepath: Path, lang: str = "ko") -> bool:
    """파일이 잘렸는지 감지"""
    content = filepath.read_text(encoding="utf-8")

    # frontmatter 분리
    match = re.match(r"^---\n(.*?)\n---\n(.+)", content, re.DOTALL)
    if not match:
        return False

    body = match.group(2).rstrip()
    if not body:
        return True

    # 마지막 비공백 줄
    lines = [l for l in body.split("\n") if l.strip()]
    if not lines:
        return True

    last_line = lines[-1].rstrip()

    # 빈 헤딩 뒤에 내용 없이 끝남
    if re.match(r'^#{2,4}\s+.+', last_line) and len(lines) > 0:
        # 헤딩이 마지막 줄이면 잘린 것
        return True

    # 문장 종결 체크
    if lang == "ko":
        if not KO_ENDINGS.search(last_line):
            return True
    elif lang == "ja":
        if not JA_ENDINGS.search(last_line):
            return True
    elif lang == "zh":
        if not ZH_ENDINGS.search(last_line):
            return True
    else:
        if not EN_ENDINGS.search(last_line):
            return True

    # 열린 코드블록 체크
    code_blocks = body.count("```")
    if code_blocks % 2 != 0:
        return True

    return False


def complete_post(filepath: Path, lang: str = "ko") -> str:
    """잘린 글을 Claude로 완성"""
    content = filepath.read_text(encoding="utf-8")

    match = re.match(r"^---\n(.*?)\n---\n(.+)", content, re.DOTALL)
    if not match:
        return content

    frontmatter = match.group(1)
    body = match.group(2)

    # frontmatter에서 제목 추출
    title_match = re.search(r'^title:\s*"?(.+?)"?\s*$', frontmatter, re.MULTILINE)
    title = title_match.group(1) if title_match else "블로그 글"

    lang_instructions = {
        "ko": "한국어로 작성. 자연스러운 한국어 문체 유지.",
        "en": "Write in English. Maintain natural English prose.",
        "ja": "日本語で書いてください。自然な日本語の文体を維持してください。",
        "zh": "用中文写作。保持自然的中文风格。",
        "es": "Escribe en español. Mantén un estilo natural en español.",
    }

    prompt = f"""다음 블로그 글이 중간에 잘려서 끝나지 않았습니다. 이어서 자연스럽게 완성해주세요.

제목: {title}
언어: {lang_instructions.get(lang, lang_instructions["ko"])}

현재까지의 본문:
{body}

규칙:
1. 잘린 부분부터 이어서 자연스럽게 완성
2. 기존 문체, 톤, 구조를 그대로 유지
3. 마크다운 볼드(**) 사용 금지
4. 물결표(~) 사용 금지, 범위는 하이픈(-) 사용
5. FAQ 섹션이 미완성이면 완성해주세요
6. 자연스러운 결론으로 마무리
7. 이어지는 부분만 출력 (이미 작성된 부분은 반복하지 마세요)

이어지는 부분만 출력:"""

    for attempt in range(2):
        response = claude.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=8192,
            messages=[{"role": "user", "content": prompt}],
        )

        continuation = response.content[0].text.strip()
        stop_reason = response.stop_reason

        if stop_reason != "end_turn":
            print(f"    [경고] 완성 응답도 잘림 (stop_reason={stop_reason}), 재시도...")
            continue

        # 완성된 전체 콘텐츠
        full_content = f"---\n{frontmatter}\n---\n{body}\n\n{continuation}"
        return full_content

    # 실패 시 원본 반환
    return content


def scan_and_fix(dry_run: bool = False, slug_filter: str = "", include_langs: bool = False):
    """모든 글 스캔 → 잘린 글 복구"""
    print("=" * 60)
    print("잘린 블로그 글 감지 & 복구")
    print(f"  모드: {'감지만 (dry-run)' if dry_run else '감지 + 복구'}")
    print(f"  번역본 포함: {'예' if include_langs else '아니오'}")
    print("=" * 60)

    # 스캔 대상 디렉토리
    scan_dirs = [("ko", POSTS_DIR)]
    if include_langs:
        for lang_dir in ["en", "ja", "zh", "es"]:
            lang_path = POSTS_DIR / lang_dir
            if lang_path.exists():
                scan_dirs.append((lang_dir, lang_path))

    truncated = []

    for lang, dir_path in scan_dirs:
        mdx_files = sorted(dir_path.glob("*.mdx"))
        for f in mdx_files:
            if slug_filter and slug_filter not in f.stem:
                continue

            if detect_truncated(f, lang):
                # 마지막 줄 미리보기
                lines = [l for l in f.read_text(encoding="utf-8").split("\n") if l.strip()]
                last = lines[-1][:60] if lines else "(empty)"
                truncated.append((lang, f, last))

    print(f"\n잘린 글 발견: {len(truncated)}개\n")

    if not truncated:
        print("모든 글이 정상입니다!")
        return

    for i, (lang, f, last) in enumerate(truncated, 1):
        print(f"  [{i:2d}] [{lang}] {f.stem}")
        print(f"       마지막: ...{last}")

    if dry_run:
        print(f"\n[dry-run] 복구하려면 --dry-run 없이 실행하세요.")
        return

    print(f"\n{'─' * 60}")
    print("복구 시작...\n")

    fixed = 0
    failed = 0

    for i, (lang, f, last) in enumerate(truncated, 1):
        print(f"[{i}/{len(truncated)}] {f.stem} ({lang})")
        try:
            completed = complete_post(f, lang)

            # 백업
            backup_path = f.with_suffix(".mdx.bak")
            if not backup_path.exists():
                f.rename(backup_path)
                # 완성본 저장
                f.write_text(completed, encoding="utf-8")
            else:
                f.write_text(completed, encoding="utf-8")

            # 복구 후 다시 검증
            if detect_truncated(f, lang):
                print(f"  [!] 복구 후에도 여전히 잘림 감지 — 수동 확인 필요")
                failed += 1
            else:
                print(f"  [OK] 복구 완료")
                fixed += 1

        except Exception as e:
            print(f"  [ERROR] {e}")
            failed += 1

    print(f"\n{'=' * 60}")
    print(f"결과: 복구 {fixed}개, 실패 {failed}개")
    if failed:
        print("실패한 글은 수동으로 확인해주세요.")
    print("=" * 60)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser(description="잘린 블로그 글 복구")
    parser.add_argument("--dry-run", action="store_true", help="감지만 (수정 안함)")
    parser.add_argument("--slug", default="", help="특정 글만")
    parser.add_argument("--lang", default="ko", help="'all'이면 번역본도 포함")
    args = parser.parse_args()

    scan_and_fix(
        dry_run=args.dry_run,
        slug_filter=args.slug,
        include_langs=(args.lang == "all"),
    )
