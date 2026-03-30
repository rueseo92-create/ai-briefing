"""모든 MDX 포스트에서 **볼드** 마크다운을 제거하는 스크립트"""
import re, sys
from pathlib import Path

if sys.stdout.encoding != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")

posts_dir = Path(__file__).parent.parent / "content" / "posts"
count = 0

for f in posts_dir.glob("*.mdx"):
    text = f.read_text(encoding="utf-8")
    # frontmatter와 본문 분리
    parts = text.split("---", 2)
    if len(parts) < 3:
        continue

    frontmatter = parts[0] + "---" + parts[1] + "---"
    body = parts[2]

    # 본문에서 **텍스트** → 텍스트 (볼드 제거)
    new_body = re.sub(r'\*\*(.+?)\*\*', r'\1', body)

    # ~~취소선~~ 제거
    new_body = re.sub(r'~~(.+?)~~', r'\1', new_body)

    if new_body != body:
        f.write_text(frontmatter + new_body, encoding="utf-8")
        # 변경된 ** 개수 세기
        removed = body.count("**") - new_body.count("**")
        print(f"  [OK] {f.name}: **{removed // 2}개 볼드 제거")
        count += 1
    else:
        print(f"  [--] {f.name}: 변경 없음")

print(f"\n완료: {count}개 파일 수정됨")
