"""
sero_blog.py - AI 브리핑 블로그 자동화 파이프라인 v4 (토큰 최적화)

파이프라인:
  1. 토픽 수집 (크롤링 + Claude)
  2. SEO 최적화 글 생성 (Claude API — 단일 호출)
  3. 프로그래밍 품질 보정 + SEO 감사 (API 호출 없음)
  4. MDX 파일 생성 (Next.js 블로그 포맷)
  5. Git push → Vercel 자동 배포

토큰 최적화:
  - 슬러그 생성: API → 프로그래밍 방식 (API 호출 제거)
  - SEO 리뷰 2차 패스: API → 프로그래밍 품질 보정 (API 호출 제거)
  - 글 생성 max_tokens: 16,384 → 8,192
  - 토픽 생성 max_tokens: 4,096 → 2,048
  - 포스트당 API 호출: 3회 → 1회 (67% 절감)

.env 필요:
  ANTHROPIC_API_KEY=sk-ant-...
  BLOG_REPO_PATH=/path/to/blog
  NAVER_CLIENT_ID=...
  NAVER_CLIENT_SECRET=...
"""

import os
import sys
import io
import json
import re
import subprocess
import random
import time
import urllib.parse
import urllib.request
from datetime import datetime, timedelta
from pathlib import Path
from dataclasses import dataclass, field
from typing import Optional

# Windows cp949 인코딩 문제 해결 — 이모지 등 유니코드 출력 지원
if sys.stdout.encoding != "utf-8":
    sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
    sys.stderr = io.TextIOWrapper(sys.stderr.buffer, encoding="utf-8", errors="replace")

import anthropic
from dotenv import load_dotenv

load_dotenv()

# ──────────────────────────────────────────────
# Config
# ──────────────────────────────────────────────
CLAUDE_MODEL = "claude-sonnet-4-20250514"
BLOG_REPO = Path(os.getenv("BLOG_REPO_PATH", str(Path(__file__).parent.parent)))
POSTS_DIR = BLOG_REPO / "content" / "posts"
SITE_URL = os.getenv("BLOG_SITE_URL", "")

# AI 브리핑 카테고리 (lib/config.ts 와 동기화)
CATEGORIES = {
    "ai-news": {"name": "AI 뉴스", "emoji": "🤖"},
    "side-hustle": {"name": "AI 부업", "emoji": "💰"},
    "ai-tools": {"name": "AI 도구", "emoji": "🛠️"},
    "marketing": {"name": "마케팅 자동화", "emoji": "📈"},
}

claude = anthropic.Anthropic()

# Google Sheets 연동
try:
    import sheets_sync
    SHEETS_ENABLED = True
    print("[Sheets] Google Sheets 연동 활성화")
except Exception:
    SHEETS_ENABLED = False
    print("[경고] Google Sheets 연결 실패 - 로컬 모드로 실행")

# 정부사업 크롤러
try:
    import gov_crawler
    CRAWLER_ENABLED = True
    print("[크롤러] 정부사업/AI 뉴스 크롤러 활성화")
except Exception:
    CRAWLER_ENABLED = False
    print("[경고] gov_crawler 로드 실패")

# K-Startup 크롤러
try:
    import kstartup_crawler
    KSTARTUP_ENABLED = True
    print("[크롤러] K-Startup 크롤러 활성화")
except Exception:
    KSTARTUP_ENABLED = False
    print("[경고] kstartup_crawler 로드 실패")


# ──────────────────────────────────────────────
# Data Classes
# ──────────────────────────────────────────────
@dataclass
class TopicData:
    """블로그 토픽 정보"""
    title: str
    category: str = "ai-news"
    summary: str = ""
    source_name: str = ""
    source_url: str = ""
    source_type: str = "news"
    difficulty: str = "beginner"
    tags: list = field(default_factory=list)
    score: float = 0.0


@dataclass
class SourceLink:
    """참고 자료 링크"""
    name: str
    url: str
    type: str = "news"  # government, paper, news, official


@dataclass
class BlogPost:
    title: str
    slug: str
    description: str
    category: str
    tags: list
    main_keyword: str
    content: str
    sources: list  # list[SourceLink]
    difficulty: str = "beginner"
    tldr: str = ""
    published: bool = False
    seo_score: float = 0.0
    reading_time: int = 0
    char_count: int = 0


# ──────────────────────────────────────────────
# SEO 유틸
# ──────────────────────────────────────────────
def analyze_keyword_density(content: str, keyword: str) -> dict:
    cleaned = re.sub(r"[#*\-_\[\]()]", "", content)
    words = len(cleaned.split())
    count = len(re.findall(re.escape(keyword), content, re.IGNORECASE))
    density = (count / words * 100) if words > 0 else 0
    status = "low" if density < 1 else ("high" if density > 3.5 else "optimal")
    return {"density": round(density, 2), "count": count, "totalWords": words, "status": status}


def calculate_reading_time(content: str) -> int:
    char_count = len(re.sub(r"\s", "", content))
    return max(1, -(-char_count // 500))


def _safe_json_parse(text: str) -> Optional[dict]:
    """잘린 JSON도 복구 시도"""
    # ```json ... ``` 래퍼 제거
    text = re.sub(r"```json\s*", "", text)
    text = re.sub(r"```\s*$", "", text)
    text = text.strip()

    try:
        return json.loads(text)
    except json.JSONDecodeError:
        print("  [경고] JSON 파싱 실패, 복구 시도...")
        # JSON 블록만 추출 시도
        match = re.search(r'\{[\s\S]*\}', text)
        if match:
            json_text = match.group(0)
            try:
                return json.loads(json_text)
            except json.JSONDecodeError:
                pass
        # 마지막 완전한 } 찾기
        last_brace = text.rfind("}")
        if last_brace > 0:
            truncated = text[:last_brace + 1]
            open_brackets = truncated.count("[") - truncated.count("]")
            open_braces = truncated.count("{") - truncated.count("}")
            truncated += "]" * max(0, open_brackets) + "}" * max(0, open_braces)
            try:
                return json.loads(truncated)
            except json.JSONDecodeError:
                pass
        return None


def _fix_markdown_tables(content: str) -> str:
    """마크다운 표가 깨지지 않도록 후처리
    - 표 행 사이 빈 줄 제거 (표 분리 방지)
    - 중복 구분선 제거
    - 구분선 없으면 헤더 뒤에 자동 삽입
    - 표 앞뒤에 빈 줄 보장
    """
    lines = content.split("\n")
    result = []
    i = 0
    while i < len(lines):
        stripped = lines[i].strip()
        # 표 블록 시작 감지
        if stripped.startswith("|") and stripped.endswith("|"):
            # 표 전체를 먼저 수집 (빈 줄 건너뛰며)
            table_rows = []
            j = i
            while j < len(lines):
                s = lines[j].strip()
                if s.startswith("|") and s.endswith("|"):
                    table_rows.append(s)
                    j += 1
                elif s == "":
                    # 빈 줄 뒤에 또 표 행이 오면 같은 표로 간주
                    k = j + 1
                    while k < len(lines) and lines[k].strip() == "":
                        k += 1
                    if k < len(lines) and lines[k].strip().startswith("|") and lines[k].strip().endswith("|"):
                        j = k  # 빈 줄 건너뛰기
                    else:
                        break
                else:
                    break
            i = j

            # 표 정리: 헤더 + 구분선 1개 + 데이터 행들
            is_sep = lambda r: bool(re.match(r'^\|[\s\-:|]+\|$', r))
            header = None
            separator = None
            data_rows = []
            for row in table_rows:
                if is_sep(row):
                    if separator is None and header is not None:
                        separator = row
                    # 중복 구분선은 무시
                elif header is None:
                    header = row
                else:
                    data_rows.append(row)

            if header:
                # 표 앞 빈 줄 보장
                if result and result[-1].strip() != "":
                    result.append("")
                result.append(header)
                # 구분선 없으면 자동 생성
                if separator is None:
                    cols = header.count("|") - 1
                    separator = "|" + "|".join(["------"] * max(cols, 1)) + "|"
                result.append(separator)
                result.extend(data_rows)
                # 표 뒤 빈 줄 보장
                result.append("")
            else:
                result.extend(table_rows)
        else:
            result.append(lines[i])
            i += 1
    return "\n".join(result)


def _generate_english_slug(title: str, fallback: str) -> str:
    """한글 제목 → SEO 친화적 영문 슬러그 (API 호출 없이 프로그래밍 방식)"""
    # 제목에서 영문/숫자만 추출
    eng_parts = re.findall(r'[a-zA-Z0-9]+', title)
    if len(eng_parts) >= 2:
        slug = "-".join(eng_parts[:6]).lower()
        if len(slug) >= 5:
            return slug
    # 한국어 키워드 → 영문 매핑 테이블
    _KR_TO_EN = {
        "사용법": "guide", "활용법": "guide", "가이드": "guide", "방법": "how-to",
        "비교": "comparison", "추천": "best", "무료": "free", "최신": "latest",
        "도구": "tools", "뉴스": "news", "부업": "side-hustle", "자동화": "automation",
        "마케팅": "marketing", "수익": "income", "시작": "getting-started",
        "입문": "beginner", "실전": "practical", "완벽": "complete",
        "리뷰": "review", "분석": "analysis", "전략": "strategy", "팁": "tips",
        "프롬프트": "prompt", "블로그": "blog", "코딩": "coding", "개발": "dev",
        "번역": "translation", "이미지": "image", "영상": "video", "음성": "voice",
        "검색": "search", "최적화": "optimization", "SEO": "seo",
        "노마드": "nomad", "원격": "remote", "프리랜서": "freelance",
    }
    parts = []
    for kr, en in _KR_TO_EN.items():
        if kr in title and en not in parts:
            parts.append(en)
        if len(parts) >= 4:
            break
    if parts:
        slug = "-".join(parts)
        if len(slug) >= 5:
            return slug
    # 최종 폴백
    fallback_slug = re.sub(r'[^a-zA-Z0-9\s-]', '', fallback).strip().replace(' ', '-').lower()
    fallback_slug = re.sub(r'-+', '-', fallback_slug).strip('-')
    return fallback_slug if len(fallback_slug) >= 3 else f"post-{random.randint(1000, 9999)}"


def _programmatic_polish(content: str, category: str) -> str:
    """AI API 없이 프로그래밍 방식으로 콘텐츠 품질 보정 (토큰 절약)"""
    # 1. 마크다운 볼드(**) 제거
    content = re.sub(r'\*\*(.+?)\*\*', r'\1', content)
    # 2. 취소선(~~) 제거
    content = re.sub(r'~~(.+?)~~', r'\1', content)
    # 3. 물결표(~) → 하이픈(-) (범위 표현)
    content = re.sub(r'(\d+)~(\d+)', r'\1-\2', content)
    # 4. H2 섹션 사이에 수평선(---) 자동 삽입
    lines = content.split("\n")
    result = []
    prev_was_h2_section = False
    for line in lines:
        if line.strip().startswith("## "):
            if prev_was_h2_section and result and result[-1].strip() != "---":
                result.append("")
                result.append("---")
                result.append("")
            prev_was_h2_section = True
        result.append(line)
    content = "\n".join(result)
    # 5. 내부 링크 부족 시 자동 추가
    internal_links = re.findall(r'\]\(/(?:posts|categories)/', content)
    if len(internal_links) < 2:
        cats = {"ai-news": "AI 뉴스", "side-hustle": "AI 부업", "ai-tools": "AI 도구", "marketing": "AI 마케팅"}
        others = [k for k in cats if k != category][:2]
        link_block = "\n\n---\n\n"
        for slug in others:
            link_block += f"[{cats[slug]} 더 보기](/categories/{slug}) | "
        link_block = link_block.rstrip(" | ")
        content += link_block
    # 6. 마크다운 표 후처리
    content = _fix_markdown_tables(content)
    return content


# ──────────────────────────────────────────────
# Step 1: 토픽 수집 (크롤링 + Claude)
# ──────────────────────────────────────────────
def collect_topics(topic: str = "AI", count: int = 5, source: str = "all") -> list[TopicData]:
    """AI 뉴스/정부사업 토픽 수집

    Args:
        topic: 주제
        count: 토픽 수
        source: 소스 ("all", "kstartup", "gov", "claude")
    """
    print(f"[1/5] 토픽 수집 중... (주제: {topic}, 소스: {source})")
    topics = []

    # K-Startup 크롤링
    if KSTARTUP_ENABLED and source in ("all", "kstartup"):
        try:
            if "모두의" in topic or "창업" in topic:
                anns = kstartup_crawler.crawl_modoo_startup(max_results=5)
            else:
                anns = kstartup_crawler.crawl_recent(days=7, max_results=5)
            for ann in anns:
                # 상세 페이지에서 추가 정보 가져오기
                detail = kstartup_crawler.crawl_detail(ann.pbanc_sn)
                detail_title = detail.get("title", "")
                org = detail.get("organization", "")
                eligibility = detail.get("eligibility", "")
                support = detail.get("support", "")

                # 실제 사업명 우선 사용
                real_title = detail_title if detail_title and len(detail_title) > 5 else ann.title

                # 요약에 실제 정보 포함
                summary_parts = []
                if org:
                    summary_parts.append(f"주관: {org}")
                if ann.deadline:
                    summary_parts.append(f"마감: {ann.deadline} (D-{ann.d_day})")
                if eligibility:
                    summary_parts.append(f"대상: {eligibility[:100]}")
                if support:
                    summary_parts.append(f"지원: {support[:100]}")
                summary = " | ".join(summary_parts) if summary_parts else f"마감: {ann.deadline} (D-{ann.d_day})"

                topics.append(TopicData(
                    title=real_title,
                    category="side-hustle",
                    summary=summary,
                    source_name="K-Startup",
                    source_url=ann.url,
                    source_type="government",
                    tags=ann.tags + ["K-Startup"],
                ))
            print(f"  → K-Startup: {len(anns)}개 공고")
        except Exception as e:
            print(f"  [K-Startup] 크롤링 실패: {e}")

    # 정부사업 크롤링
    if CRAWLER_ENABLED and source in ("all", "gov"):
        try:
            crawled = gov_crawler.crawl_all(max_per_source=3)
            for item in crawled:
                topics.append(TopicData(
                    title=item.title,
                    category=item.category if item.category in CATEGORIES else "ai-news",
                    summary=item.summary,
                    source_name=item.source,
                    source_url=item.url,
                    source_type=item.source_type,
                    tags=item.tags,
                ))
        except Exception as e:
            print(f"  [gov_crawler] 크롤링 실패: {e}")

    # 토픽이 부족하면 Claude로 보충
    if len(topics) < count and source in ("all", "claude"):
        claude_topics = _generate_topics_claude(topic, min(count + 2, 12))
        topics.extend(claude_topics)

    # 점수 부여
    for t in topics:
        score = 5.0
        if t.category == "side-hustle":
            score += 3  # AI 부업/노마드 콘텐츠 우선
        if t.source_url:
            score += 2  # 출처가 있는 콘텐츠 우선
        if any(kw in t.title for kw in ["지원", "공모", "무료", "신청"]):
            score += 2  # 실용성 높은 키워드
        t.score = score

    topics.sort(key=lambda x: x.score, reverse=True)
    print(f"  → {len(topics)}개 토픽 수집 (상위 {count}개 선택)")
    for i, t in enumerate(topics[:count]):
        print(f"  {i+1}. [{t.category}] {t.title} (점수: {t.score:.1f})")

    return topics[:count]


def _generate_topics_claude(topic: str, count: int) -> list[TopicData]:
    """Claude로 블로그 토픽 생성"""
    today = datetime.now().strftime("%Y-%m-%d")
    one_week_ago = (datetime.now() - timedelta(days=7)).strftime("%Y-%m-%d")

    prompt = f"""당신은 한국 AI 블로그 에디터입니다.
오늘 날짜: {today}

"{topic}" 주제로 블로그 포스팅에 적합한 토픽 {count}개를 생성해주세요.

핵심 조건:
- 반드시 2026년 최신 정보만 다룰 것
- {one_week_ago} ~ {today} 사이에 발표/공개/업데이트된 내용 위주
- 과거 연도(2024, 2025) 정보를 현재처럼 쓰지 말 것

절대 금지 (할루시네이션 방지):
- 존재하지 않는 정부사업, 지원금, 공모전을 만들어내지 말 것
- 실제 확인되지 않은 URL을 만들지 말 것
- 구체적 금액/마감일/선정 규모 등을 지어내지 말 것
토픽 유형 (골고루 섞어서):
- ai-news: AI 업계 최신 뉴스, 모델 출시, 기업 동향 (이번 주 뉴스)
- ai-tools: ChatGPT, Claude, Midjourney 등 AI 도구 최신 업데이트/비교/활용법
- marketing: AI 기반 마케팅 자동화 전략, 도구, 퍼널, CRM, 이메일/SNS 자동화
- side-hustle: AI 부업, 디지털노마드, 자동화 수익, 프리랜서 가이드, 패시브 인컴, 원격근무

제목 작성 (후킹 필수!):
- 클릭을 유도하는 강력한 후킹 제목 (50자 이내)
- 숫자 활용: "TOP 5", "3가지", "최대 3억"
- 감정/호기심 유발: "직접 써보니", "1등은 의외", "이것 모르면 손해"
- 긴급성: "마감 임박", "이번 달까지", "서두르세요"
- 대화체/구어체: "~해봤습니다", "~할까?", "~라고?"
- 나쁜 예: "2026년 AI 도구 비교 분석 가이드"
- 좋은 예: "AI 번역기 7개 직접 비교해봤습니다 (1등은 의외)"

SEO 기준:
- 구글 검색에 잘 걸리는 키워드 포함
- "무료", "사용법", "비교", "추천" 등 검색 의도 키워드 활용
- 한국어 사용자가 실제로 검색할 만한 제목

반드시 아래 JSON만 출력:
{{
  "topics": [
    {{
      "title": "블로그 제목 (60자 이하, SEO 최적화, 2026년 포함)",
      "category": "ai-news/ai-tools/marketing/side-hustle",
      "summary": "핵심 내용 2-3줄 (2026년 기준)",
      "difficulty": "beginner/intermediate/advanced",
      "tags": ["태그1", "태그2", "태그3", "태그4"]
    }}
  ]
}}"""

    for attempt in range(3):
        try:
            response = claude.messages.create(
                model=CLAUDE_MODEL,
                max_tokens=2048,
                messages=[{"role": "user", "content": prompt}],
            )
            text = response.content[0].text.strip()
            data = _safe_json_parse(text)
            if data and "topics" in data:
                break
        except Exception as e:
            print(f"  [토픽 생성] 시도 {attempt+1}/3 실패: {e}")
            if attempt == 2:
                return []

    if not data or "topics" not in data:
        print("  [토픽 생성] JSON 파싱 실패")
        return []

    results = []
    for t in data.get("topics", []):
        results.append(TopicData(
            title=t["title"],
            category=t.get("category", "ai-news"),
            summary=t.get("summary", ""),
            difficulty=t.get("difficulty", "beginner"),
            tags=t.get("tags", []),
        ))
    return results


# ──────────────────────────────────────────────
# Step 2: SEO 최적화 글 생성
# ──────────────────────────────────────────────
BLOG_PROMPT = """당신은 SEO·GEO(Generative Engine Optimization)에 특화된 한국어 AI 블로그 작가이자 콘텐츠 디자이너입니다.
아래 토픽에 대해 시각적으로 풍부하고 읽기 쉬운 블로그 글을 작성해주세요.

토픽: {title}
카테고리: {category}
요약: {summary}
난이도: {difficulty}
오늘 날짜: {today}

작성 규칙:
1. SEO 최적화 + 후킹 제목 (구글 검색 상위 노출)
   - 제목은 클릭을 유도하는 후킹 스타일, 50자 이내
   - 숫자, 감정, 호기심, 대화체 활용 ("직접 써보니", "이것 모르면 손해", "1등은 의외")
   - 소제목(H2, H3)에 키워드 변형 자연스럽게 배치
   - 첫 100자 이내에 핵심 키워드 언급
   - 키워드 밀도 1~3% 유지
   - meta description 150자 이하
   - FAQ 섹션 포함 (구글 리치 스니펫 대응)

2. 글 구조 (시각적 계층)
   - 도입: 독자의 고민/질문으로 공감 (2~3문장, "혹시 ~하신 적 있나요?")
   - 본론: 3~5개 H2 섹션, 각 섹션에 H3 포함
   - H2 섹션 사이에 반드시 수평선(---) 삽입 (시각적 구분)
   - 구체적인 숫자, 날짜, 사례 포함
   - 결론: 핵심 요약 + 다음 단계 안내
   - FAQ: 자주 묻는 질문 2-3개 (### Q1. 질문 / A1. 답변 형식)

3. GEO 최적화 — AI 검색엔진 인용 극대화 (매우 중요!)
   - 통계/수치 삽입: 150~200자마다 구체적 통계·수치를 포함
     예: "2026년 기준 국내 AI 시장 규모는 약 15조 원으로 전년 대비 35% 성장했다"
     (AI 검색 인용률 +30~40% 효과)
   - 인용 가능한 답변 캡슐: 핵심 질문에 대해 40~60자 분량의 명확한 한 줄 답변 제공
     형식: > 핵심 답변: [질문에 대한 명확하고 간결한 답변 40~60자]
     (AI가 직접 인용하기 좋은 구조, 검색 노출 +20~30%)
   - 출처 인용: 본문 내에서 "(출처: OOO, 2026)" 형태로 신뢰도 표시
     (AI 인용률 +30~40% 효과)
   - 엔티티 관계: 핵심 개념 간 관계를 명시적으로 서술
     예: "ChatGPT는 OpenAI가 개발한 대규모 언어 모델로, GPT-4 아키텍처 기반이다"
   - E-E-A-T 신호: 경험·전문성·권위·신뢰를 드러내는 표현 포함
     예: "실제 3개월간 테스트한 결과", "공식 문서에 따르면", "업계 전문가들의 분석"

4. 콘텐츠 디자인 규칙 — 매우 중요!
   - 핵심 정보는 인용블록(>)으로 강조 (최소 3개 포함)
     예시: > 핵심: ChatGPT-4는 무료 버전도 충분히 강력합니다.
     예시: > 꿀팁: 프롬프트에 "단계별로 설명해줘"를 추가하면 답변 품질이 올라갑니다.
     예시: > 핵심 답변: AI가 인용할 수 있는 간결한 답변
   - 마크다운 볼드(**) 절대 사용 금지 — 본문에 ** 기호를 넣지 마세요
   - ~~취소선~~ 사용 금지
   - 물결표(~) 사용 금지 — 범위 표현 시 하이픈(-) 사용 (예: "2-4주", "50-100자", "30-40%")
   - 이모지 절제: 1섹션당 최대 2개 (과다 사용 금지)
   - 스캔 가능성: 3초 안에 핵심이 눈에 들어오도록 구조화
   - 내부 링크: [관련 글 보기](/categories/카테고리슬러그) 형태로 2개 이상 포함
   - 체크리스트: 실행 단계는 순서 있는 목록(1. 2. 3.)으로 작성

5. 톤 & 스타일
   - 전문적이면서도 쉬운 설명 ("~거든요", "~인데요")
   - 비전공자도 이해할 수 있는 수준
   - 비유와 예시 적극 활용
   - 광고 느낌 없는 정보성 콘텐츠
   - 형광색, 빨간 밑줄, 깜빡이는 텍스트 같은 저급한 꾸밈 금지

6. 분량: 2500~3500자

7. 정보 정확성 (매우 중요! — 할루시네이션 절대 금지)
   - 존재하지 않는 사업, 보조금, 공모전을 절대 만들어내지 말 것
   - 구체적 지원금액, 마감일, 선정 규모를 지어내지 말 것
   - 실제 확인되지 않은 URL을 절대 만들지 말 것
   - 출처 URL은 반드시 실제 존재하는 공식 도메인의 메인 페이지만 사용
     예: "https://openai.com", "https://www.msit.go.kr" (OK)
     예: "https://msit.go.kr/ai-startup-2026" (금지 — 실제 존재 확인 불가)
   - 확실하지 않은 정보는 "~로 알려져 있다", "~한 것으로 보인다"와 같은 추정 표현 사용
   - 정부 정책/사업 정보는 크롤링으로 확인된 경우에만 구체적으로 언급
   - 반드시 2026년 최신 정보만 작성 (과거 연도 정보 사용 금지)
   - "2024년", "2025년" 등 과거 데이터를 현재 정보처럼 쓰지 말 것

8. 표(Table) 작성 규칙 — 중요!
   - 비교/목록 데이터는 반드시 마크다운 표로 정리
   - 표 위에 반드시 빈 줄 1개, 표 아래에도 빈 줄 1개 필수
   - 표 형식을 정확히 지킬 것:

| 항목 | 내용 | 비고 |
|------|------|------|
| 데이터1 | 설명1 | 참고1 |
| 데이터2 | 설명2 | 참고2 |

   - 헤더 구분선은 반드시 |------|------|------| 형태 (하이픈 3개 이상)
   - 셀 안에 파이프(|) 문자 사용 금지
   - 최소 1개 이상의 표를 포함할 것

9. 참고 자료 (출처 URL 규칙)
   - sources의 URL은 반드시 실제 존재하는 공식 웹사이트의 메인 페이지 또는 알려진 경로만 사용
   - 절대 URL을 지어내지 말 것. 확실하지 않으면 해당 기관의 메인 도메인만 제공
   - 허용 예: "https://openai.com", "https://www.anthropic.com", "https://www.msit.go.kr"
   - 금지 예: "https://msit.go.kr/specific-fake-path-2026" (존재 확인 불가능한 경로)
   - 출처는 신뢰도 높은 기관 우선 (공식 사이트, 학술, 공식 보고서)

반드시 아래 JSON만 출력:
{{
  "title": "SEO 최적화된 제목 (60자 이하)",
  "description": "meta description (150자 이내)",
  "tldr": "핵심 내용 1-2문장 TL;DR",
  "tags": ["태그1", "태그2", "태그3", "태그4", "태그5"],
  "content": "마크다운 본문 전체 (H2, H3, 목록, 표, 인용블록, 수평선, FAQ, 통계, 답변캡슐 포함)",
  "sources": [
    {{
      "name": "출처 이름",
      "url": "출처 URL",
      "type": "government/news/official/paper"
    }}
  ]
}}"""


def _validate_source_url(url: str) -> bool:
    """출처 URL이 합리적인지 간단 검증 (가짜 경로 차단)"""
    if not url or not url.startswith("http"):
        return False
    # 메인 도메인만 허용하거나 알려진 경로 패턴만 허용
    # 너무 구체적인 가짜 경로 차단 (예: /ai-startup-2026, /voucher-2026)
    suspicious_patterns = [
        r"/ai-\w+-202[0-9]",  # /ai-something-2026 같은 만들어낸 경로
        r"/voucher-202[0-9]",
        r"/startup-202[0-9]",
        r"/subsidy-202[0-9]",
    ]
    for pat in suspicious_patterns:
        if re.search(pat, url):
            return False
    return True


def generate_blog_post(topic: TopicData) -> BlogPost:
    """Claude API로 SEO 최적화 블로그 글 생성"""
    # 카테고리 유효성 검증
    if topic.category not in CATEGORIES:
        print(f"  [경고] 알 수 없는 카테고리 '{topic.category}' → ai-news로 변경")
        topic.category = "ai-news"

    print(f"[2/5] 블로그 글 생성 중... (토픽: {topic.title})")

    prompt_content = BLOG_PROMPT.format(
        title=topic.title,
        category=CATEGORIES.get(topic.category, {}).get("name", topic.category),
        summary=topic.summary or "최신 AI 트렌드 관련 정보",
        difficulty=topic.difficulty,
        today=datetime.now().strftime("%Y-%m-%d"),
    )

    data = None
    for attempt in range(2):
        response = claude.messages.create(
            model=CLAUDE_MODEL,
            max_tokens=8192,
            messages=[{"role": "user", "content": prompt_content}],
        )
        text = response.content[0].text.strip()
        stop_reason = response.stop_reason

        # 잘림 감지: end_turn이 아닌 경우 (max_tokens 등)
        if stop_reason != "end_turn":
            print(f"  [경고] 응답이 잘렸습니다 (stop_reason={stop_reason}), 재시도...")
            continue

        text = re.sub(r"```json\s*|```", "", text).strip()
        data = _safe_json_parse(text)
        if data and "content" in data:
            # 본문 잘림 추가 검증: 마지막 문자가 문장 종결인지 확인
            content = data["content"].rstrip()
            if content and not content[-1] in ".다요죠세습까!?\n":
                print(f"  [경고] 본문이 중간에 끊김 감지, 재시도...")
                continue
            break
        print(f"  [재시도 {attempt+1}/2] JSON 파싱 실패, 다시 생성...")

    if data is None or "content" not in data:
        raise RuntimeError(f"2회 시도 후에도 JSON 생성 실패: {topic.title}")

    # 프로그래밍 품질 보정 (API 없이 — 토큰 절약)
    data["content"] = _programmatic_polish(data["content"], topic.category)

    # 소스 링크 처리 (가짜 URL 필터링)
    sources = []
    for s in data.get("sources", []):
        url = s.get("url", "")
        if url and not _validate_source_url(url):
            print(f"  [필터] 의심스러운 출처 URL 제거: {url}")
            continue
        sources.append(SourceLink(
            name=s.get("name", "출처"),
            url=url,
            type=s.get("type", "news"),
        ))
    # 크롤링 원본 출처 추가
    if topic.source_url:
        sources.insert(0, SourceLink(
            name=topic.source_name or "원문",
            url=topic.source_url,
            type=topic.source_type or "news",
        ))

    today = datetime.now().strftime("%Y-%m-%d")
    title = data["title"]
    slug = f"{today}-{_generate_english_slug(title, topic.title)}"

    post = BlogPost(
        title=title,
        slug=slug[:80],
        description=data.get("description", ""),
        category=topic.category,
        tags=data.get("tags", topic.tags),
        main_keyword=topic.title,
        content=data["content"],
        sources=sources,
        difficulty=topic.difficulty,
        tldr=data.get("tldr", ""),
    )

    print(f"  → 제목: {post.title}")
    return post


def run_seo_audit(post: BlogPost) -> BlogPost:
    """SEO 감사 실행"""
    print("[3/5] SEO 점수 산출 중...")

    content = post.content
    # 통계/수치 패턴: 숫자+단위 조합
    stat_patterns = re.findall(r"\d+[\d,.]*\s*(?:%|조|억|만|건|개|명|달러|원|배|위)", content)
    # 답변 캡슐 패턴
    answer_capsules = re.findall(r">\s*(?:\*\*)?핵심\s*(?:답변|정보|요약)[:：]?(?:\*\*)?", content)
    # 출처 인용 패턴
    source_citations = re.findall(r"\(출처[:：]?\s*.+?\)", content)
    # 내부 링크 수
    internal_links = re.findall(r"\]\(/(?:posts|categories)/", content)

    checks = [
        # SEO 기본
        {"label": "제목 60자 이하", "passed": len(post.title) <= 60},
        {"label": "description 155자 이하", "passed": 0 < len(post.description) <= 155},
        {"label": "H2 3개 이상", "passed": len(re.findall(r"^## ", content, re.MULTILINE)) >= 3},
        {"label": "H3 존재", "passed": len(re.findall(r"^### ", content, re.MULTILINE)) >= 1},
        {"label": "본문 1000자 이상", "passed": len(re.sub(r"\s", "", content)) >= 1000},
        {"label": "FAQ 섹션", "passed": "FAQ" in content or "자주 묻는" in content or "Q." in content},
        {"label": "내부 링크 2개+", "passed": len(internal_links) >= 2},
        {"label": "태그 3개 이상", "passed": len(post.tags) >= 3},
        {"label": "TL;DR 존재", "passed": bool(post.tldr)},
        {"label": "출처 링크", "passed": len(post.sources) > 0},
        # GEO 최적화
        {"label": "통계/수치 4개+", "passed": len(stat_patterns) >= 4},
        {"label": "답변 캡슐 2개+", "passed": len(answer_capsules) >= 2},
        {"label": "본문 출처 인용 2개+", "passed": len(source_citations) >= 2},
    ]

    passed = sum(1 for c in checks if c["passed"])
    score = round((passed / len(checks)) * 100)

    density = analyze_keyword_density(content, post.main_keyword)
    reading = calculate_reading_time(content)
    chars = len(re.sub(r"\s", "", content))

    post.seo_score = score
    post.reading_time = reading
    post.char_count = chars

    print(f"  → SEO 점수: {score}/100 ({passed}/{len(checks)} 통과)")
    print(f"  → 키워드 밀도: {density['density']:.1f}% | 읽기: {reading}분 | {chars:,}자")

    failed = [c for c in checks if not c["passed"]]
    if failed:
        print("  → 미통과: " + ", ".join(c["label"] for c in failed))

    return post


# ──────────────────────────────────────────────
# 60개 고유 Unsplash 썸네일 풀 (lib/posts.ts 와 동기화)
# ──────────────────────────────────────────────
_THUMBNAIL_POOL = [
    # AI / 테크
    "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80",
    "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80",
    "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&q=80",
    "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&q=80",
    "https://images.unsplash.com/photo-1535378620166-273708d44e4c?w=800&q=80",
    "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&q=80",
    "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800&q=80",
    "https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80",
    "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&q=80",
    "https://images.unsplash.com/photo-1504639725590-34d0984388bd?w=800&q=80",
    "https://images.unsplash.com/photo-1633356122544-f134324a6cee?w=800&q=80",
    "https://images.unsplash.com/photo-1550645612-83f5d594b671?w=800&q=80",
    # 비즈니스 / 오피스
    "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80",
    "https://images.unsplash.com/photo-1523292562811-8fa7962a78c8?w=800&q=80",
    "https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&q=80",
    "https://images.unsplash.com/photo-1577415124269-fc1140a69e91?w=800&q=80",
    "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800&q=80",
    "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80",
    "https://images.unsplash.com/photo-1553877522-43269d4ea984?w=800&q=80",
    "https://images.unsplash.com/photo-1522071820081-009f0129c71c?w=800&q=80",
    "https://images.unsplash.com/photo-1552664730-d307ca884978?w=800&q=80",
    "https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?w=800&q=80",
    "https://images.unsplash.com/photo-1557804506-669a67965ba0?w=800&q=80",
    "https://images.unsplash.com/photo-1519389950473-47ba0277781c?w=800&q=80",
    # 개발 / 코딩
    "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800&q=80",
    "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&q=80",
    "https://images.unsplash.com/photo-1587620962725-abab7fe55159?w=800&q=80",
    "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800&q=80",
    "https://images.unsplash.com/photo-1555949963-aa79dcee981c?w=800&q=80",
    "https://images.unsplash.com/photo-1542831371-29b0f74f9713?w=800&q=80",
    "https://images.unsplash.com/photo-1517694712202-14dd9538aa97?w=800&q=80",
    "https://images.unsplash.com/photo-1488590528505-98d2b5aba04b?w=800&q=80",
    # 마케팅 / 데이터
    "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&q=80",
    "https://images.unsplash.com/photo-1533750516457-a7f992034fec?w=800&q=80",
    "https://images.unsplash.com/photo-1432888498266-38ffec3eaf0a?w=800&q=80",
    "https://images.unsplash.com/photo-1560472355-536de3962603?w=800&q=80",
    "https://images.unsplash.com/photo-1504868584819-f8e8b4b6d7e3?w=800&q=80",
    "https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?w=800&q=80",
    "https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&q=80",
    "https://images.unsplash.com/photo-1596558450268-9c27524ba856?w=800&q=80",
    # 사이언스 / 혁신
    "https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=800&q=80",
    "https://images.unsplash.com/photo-1576086213369-97a306d36557?w=800&q=80",
    "https://images.unsplash.com/photo-1507413245164-6160d8298b31?w=800&q=80",
    "https://images.unsplash.com/photo-1532094349884-543bc11b234d?w=800&q=80",
    "https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800&q=80",
    "https://images.unsplash.com/photo-1573164713714-d95e436ab8d6?w=800&q=80",
    # 인프라 / 클라우드
    "https://images.unsplash.com/photo-1563986768609-322da13575f2?w=800&q=80",
    "https://images.unsplash.com/photo-1580894894513-541e068a3e2b?w=800&q=80",
    "https://images.unsplash.com/photo-1531297484001-80022131f5a1?w=800&q=80",
    "https://images.unsplash.com/photo-1605810230434-7631ac76ec81?w=800&q=80",
    "https://images.unsplash.com/photo-1573164574572-cb89e39749b4?w=800&q=80",
    # 스타트업 / 팀워크
    "https://images.unsplash.com/photo-1559136555-9303baea8ebd?w=800&q=80",
    "https://images.unsplash.com/photo-1524758631624-e2822e304c36?w=800&q=80",
    "https://images.unsplash.com/photo-1483058712412-4245e9b90334?w=800&q=80",
    "https://images.unsplash.com/photo-1496181133206-80ce9b88a853?w=800&q=80",
    # 헬스케어 / 리서치
    "https://images.unsplash.com/photo-1584036561566-baf8f5f1b144?w=800&q=80",
    "https://images.unsplash.com/photo-1581093458791-9d42e3c2fd75?w=800&q=80",
    "https://images.unsplash.com/photo-1559757175-5700dde675bc?w=800&q=80",
    "https://images.unsplash.com/photo-1581093450021-4a7360e9a6b5?w=800&q=80",
    # 디지털 / 모바일
    "https://images.unsplash.com/photo-1569017388730-020b5f80a004?w=800&q=80",
    "https://images.unsplash.com/photo-1512756290469-ec264b7fbf87?w=800&q=80",
]


def _pick_thumbnail(slug: str, category: str) -> str:
    """슬러그 알파벳순 인덱스 기반 고유 이미지 할당 (중복 없음)"""
    existing = sorted(
        f.stem for f in POSTS_DIR.glob("*.mdx")
    ) if POSTS_DIR.exists() else []
    # 새 글이 아직 디스크에 없으면 추가 후 정렬
    if slug not in existing:
        existing.append(slug)
        existing.sort()
    idx = existing.index(slug)
    return _THUMBNAIL_POOL[idx % len(_THUMBNAIL_POOL)]


# ──────────────────────────────────────────────
# Step 5: MDX 파일 생성
# ──────────────────────────────────────────────
def create_mdx_file(post: BlogPost) -> Path:
    """Next.js 블로그 호환 MDX 파일 생성"""
    print("[4/5] MDX 파일 생성 중...")

    filename = f"{post.slug[:80]}.mdx"

    # sources YAML
    sources_yaml = ""
    for s in post.sources:
        sources_yaml += f'\n  - name: "{s.name}"\n    url: "{s.url}"\n    type: "{s.type}"'

    # 카테고리별 Unsplash 썸네일 자동 할당
    thumbnail = _pick_thumbnail(post.slug, post.category)

    mdx = f"""---
title: "{post.title}"
description: "{post.description}"
date: "{datetime.now().strftime('%Y-%m-%dT%H:%M:%S')}"
category: "{post.category}"
tags: {json.dumps(post.tags, ensure_ascii=False)}
thumbnail: "{thumbnail}"
difficulty: "{post.difficulty}"
tldr: "{post.tldr}"
published: {str(post.published).lower()}
sources:{sources_yaml if sources_yaml else " []"}
---

{post.content}
"""

    POSTS_DIR.mkdir(parents=True, exist_ok=True)
    filepath = POSTS_DIR / filename
    filepath.write_text(mdx, encoding="utf-8")

    print(f"  → 파일: {filepath}")
    return filepath


# ──────────────────────────────────────────────
# Step 6: Git Push
# ──────────────────────────────────────────────
def deploy(filepath: Path) -> bool:
    """Git commit & push"""
    print("[5/5] 배포 중...")
    try:
        subprocess.run(["git", "add", str(filepath)], cwd=str(BLOG_REPO), check=True, capture_output=True)
        subprocess.run(["git", "commit", "-m", f"feat: 새 글 - {filepath.stem}"], cwd=str(BLOG_REPO), check=True, capture_output=True)
        subprocess.run(["git", "push"], cwd=str(BLOG_REPO), check=True, capture_output=True)
        print("  → Git push 완료")
        return True
    except subprocess.CalledProcessError as e:
        print(f"  [배포 실패] {e}")
        return False


# ──────────────────────────────────────────────
# Step 7: 기록
# ──────────────────────────────────────────────
def record_to_sheets(post: BlogPost, filepath: Path, deployed: bool):
    if not SHEETS_ENABLED:
        return
    try:
        slug = filepath.stem if filepath else post.slug
        sheets_sync.log_post({
            "slug": slug,
            "title": post.title,
            "category": post.category,
            "status": "published" if deployed else "draft",
            "date": datetime.now().strftime("%Y-%m-%d"),
            "keyword": post.main_keyword,
            "search_volume": "",
            "seo_score": f"{post.seo_score:.0f}",
            "reading_time": f"{post.reading_time}",
            "coupang_products": len(post.sources),
            "tags": post.tags,
            "url": f"{SITE_URL}/posts/{slug}" if SITE_URL else "",
            "notes": f"difficulty:{post.difficulty} chars:{post.char_count}",
        })
    except Exception as e:
        print(f"  [Sheets] 기록 실패: {e}")


# ──────────────────────────────────────────────
# Main Pipeline
# ──────────────────────────────────────────────
def run_pipeline(
    topic: str = "AI",
    count: int = 1,
    publish: bool = True,
    dry_run: bool = False,
    source: str = "all",
):
    """전체 파이프라인 실행

    Args:
        topic: 주제 (예: "AI", "정부사업 AI", "생성형AI", "모두의 창업")
        count: 생성할 글 수
        publish: True면 published: true
        dry_run: True면 파일 생성만 (배포 안함)
        source: 데이터 소스 ("all", "kstartup", "gov", "claude")
    """
    pipeline_start = time.time()
    print("=" * 60)
    print(f"AI 브리핑 파이프라인 v4 (토큰 최적화)")
    print(f"   주제: {topic} | 생성: {count}편 | 발행: {publish}")
    print(f"   소스: {source}")
    print(f"   모드: {'Dry-run' if dry_run else 'Full'}")
    print(f"   시각: {datetime.now().strftime('%Y-%m-%d %H:%M')}")
    print("=" * 60)

    # 1. 토픽 수집
    topics = collect_topics(topic, count + 2, source=source)

    results = []
    for i, topic_data in enumerate(topics[:count]):
        print(f"\n{'─' * 40}")
        print(f"[글 {i+1}/{count}] {topic_data.title}")
        print(f"{'─' * 40}")

        try:
            # 2. 글 생성 + 프로그래밍 품질 보정 (단일 API 호출)
            post = generate_blog_post(topic_data)
            post.published = publish

            # 3. SEO 감사 (API 호출 없음 — 프로그래밍 방식)
            post = run_seo_audit(post)

            # 5. 파일 생성
            filepath = create_mdx_file(post)

            # 6. 배포
            deployed = False
            if not dry_run and filepath:
                deployed = deploy(filepath)

            # 7. 기록
            record_to_sheets(post, filepath, deployed)

            results.append({
                "title": post.title,
                "category": post.category,
                "seo_score": post.seo_score,
                "char_count": post.char_count,
                "reading_time": post.reading_time,
                "file": str(filepath.name) if filepath else "",
                "deployed": deployed,
            })
        except Exception as e:
            print(f"  [오류] 글 생성 실패: {e}")
            print("  → 다음 글로 넘어갑니다.")

        if i < count - 1:
            print("\n다음 글 생성 전 3초 대기...")
            time.sleep(3)

    # 결과 요약
    pipeline_end = time.time()
    duration = int(pipeline_end - pipeline_start)
    print("\n" + "=" * 60)
    print(f"파이프라인 완료! ({duration}초)")
    print(f"   생성: {len(results)}편")
    for r in results:
        status = "LIVE" if r["deployed"] else "FILE"
        print(f"   [{status}] {r['title']}")
        print(f"         SEO: {r['seo_score']:.0f} | {r['char_count']:,}자 | {r['reading_time']}분")
    print("=" * 60)

    # Sheets 로그
    if SHEETS_ENABLED:
        try:
            sheets_sync.log_pipeline_run({
                "run_id": datetime.now().strftime("%Y%m%d_%H%M%S"),
                "niche": topic,
                "posts_generated": len(results),
                "posts_published": sum(1 for r in results if r["deployed"]),
                "errors": count - len(results),
                "duration_sec": duration,
                "status": "success" if len(results) == count else "partial",
            })
        except Exception as e:
            print(f"  [Sheets] 로그 실패: {e}")

    return results


# ──────────────────────────────────────────────
# CLI
# ──────────────────────────────────────────────
if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="AI 브리핑 블로그 자동화 파이프라인 v3")
    parser.add_argument("--topic", type=str, default="AI", help="주제 (예: AI, 정부사업, 모두의 창업)")
    parser.add_argument("--count", type=int, default=1, help="생성할 글 수 (기본: 1)")
    parser.add_argument("--source", type=str, default="all", choices=["all", "kstartup", "gov", "claude"],
                        help="데이터 소스 (기본: all)")
    parser.add_argument("--draft", action="store_true", help="임시저장")
    parser.add_argument("--dry-run", action="store_true", help="배포 없이 파일만 생성")
    args = parser.parse_args()

    run_pipeline(
        topic=args.topic,
        count=args.count,
        publish=not args.draft,
        dry_run=args.dry_run,
        source=args.source,
    )
