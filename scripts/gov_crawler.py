"""
gov_crawler.py - 정부 AI 사업/지원 정보 크롤링

크롤링 소스:
  1. IITP (정보통신기획평가원) 공고
  2. NIA (한국지능정보사회진흥원) 공고
  3. MSIT (과학기술정보통신부) 보도자료
  4. K-Startup 공고
  5. AI Times 뉴스 (AI 전문 매체)

각 소스에서 최신 AI 관련 공고/뉴스를 수집하여
Claude API로 쉬운 설명을 생성합니다.
"""

import json
import re
import urllib.parse
import urllib.request
from datetime import datetime
from dataclasses import dataclass, field


@dataclass
class GovProject:
    """정부사업/뉴스 정보"""
    title: str
    url: str
    source: str  # "IITP", "NIA", "MSIT", "K-Startup", "AI Times"
    source_type: str  # "government", "news", "official"
    date: str = ""
    summary: str = ""
    category: str = ""  # "지원사업", "공모", "정책", "뉴스"
    budget: str = ""
    deadline: str = ""
    tags: list = field(default_factory=list)


# ─── RSS / 웹 크롤링 ──────────────────────────

def _fetch_url(url: str, timeout: int = 15) -> str:
    """URL 내용 가져오기"""
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36"
    })
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8", errors="replace")


def _extract_rss_items(xml: str, max_items: int = 10) -> list[dict]:
    """간단한 RSS XML 파싱 (외부 라이브러리 없이)"""
    items = []
    for item_match in re.finditer(r"<item>(.*?)</item>", xml, re.DOTALL):
        item_xml = item_match.group(1)
        title = re.search(r"<title>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</title>", item_xml, re.DOTALL)
        link = re.search(r"<link>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</link>", item_xml, re.DOTALL)
        desc = re.search(r"<description>(?:<!\[CDATA\[)?(.*?)(?:\]\]>)?</description>", item_xml, re.DOTALL)
        pub_date = re.search(r"<pubDate>(.*?)</pubDate>", item_xml, re.DOTALL)

        if title and link:
            items.append({
                "title": re.sub(r"<[^>]+>", "", title.group(1)).strip(),
                "link": link.group(1).strip(),
                "description": re.sub(r"<[^>]+>", "", desc.group(1)).strip() if desc else "",
                "date": pub_date.group(1).strip() if pub_date else "",
            })
        if len(items) >= max_items:
            break
    return items


# ─── AI 관련 필터링 ──────────────────────────

AI_KEYWORDS = [
    "인공지능", "AI", "머신러닝", "딥러닝", "GPT", "LLM", "생성형",
    "챗봇", "자연어처리", "NLP", "컴퓨터비전", "데이터", "클라우드",
    "디지털", "스마트", "자율주행", "로봇", "빅데이터", "메타버스",
    "블록체인", "IoT", "사물인터넷", "XR", "반도체", "SW", "소프트웨어",
    "정보통신", "ICT", "테크", "스타트업", "혁신", "R&D",
]


def _is_ai_related(title: str, description: str = "") -> bool:
    """AI 관련 콘텐츠인지 필터링"""
    text = f"{title} {description}".lower()
    return any(kw.lower() in text for kw in AI_KEYWORDS)


# ─── 소스별 크롤러 ──────────────────────────

def crawl_msit_news(max_items: int = 5) -> list[GovProject]:
    """과학기술정보통신부 보도자료 RSS"""
    print("  [MSIT] 과학기술정보통신부 보도자료 크롤링...")
    try:
        xml = _fetch_url("https://www.msit.go.kr/bbs/list.do?bbsId=B0000001&pageIndex=1&nttId=&searchWrd=&categoryId=rss")
        items = _extract_rss_items(xml, max_items * 3)
        results = []
        for item in items:
            if _is_ai_related(item["title"], item["description"]):
                results.append(GovProject(
                    title=item["title"],
                    url=item["link"],
                    source="MSIT",
                    source_type="government",
                    date=item.get("date", ""),
                    summary=item.get("description", "")[:200],
                    category="정책",
                    tags=["과기부", "정책"],
                ))
            if len(results) >= max_items:
                break
        print(f"  [MSIT] {len(results)}개 AI 관련 항목")
        return results
    except Exception as e:
        print(f"  [MSIT] 크롤링 실패: {e}")
        return []


def crawl_iitp_projects(max_items: int = 5) -> list[GovProject]:
    """IITP 정보통신기획평가원 사업공고"""
    print("  [IITP] 정보통신기획평가원 사업공고 크롤링...")
    try:
        url = "https://www.iitp.kr/kr/1/business/businessNotice/list.it"
        html = _fetch_url(url)
        results = []

        # 간단한 HTML 파싱으로 공고 제목/링크 추출
        rows = re.findall(r'<a[^>]*href=["\']([^"\']*)["\'][^>]*>(.*?)</a>', html, re.DOTALL)
        for link, title_html in rows:
            title = re.sub(r"<[^>]+>", "", title_html).strip()
            if title and len(title) > 5 and _is_ai_related(title):
                full_url = link if link.startswith("http") else f"https://www.iitp.kr{link}"
                results.append(GovProject(
                    title=title,
                    url=full_url,
                    source="IITP",
                    source_type="government",
                    category="지원사업",
                    tags=["IITP", "R&D", "지원사업"],
                ))
            if len(results) >= max_items:
                break
        print(f"  [IITP] {len(results)}개 AI 관련 항목")
        return results
    except Exception as e:
        print(f"  [IITP] 크롤링 실패: {e}")
        return []


def crawl_nia_projects(max_items: int = 5) -> list[GovProject]:
    """NIA 한국지능정보사회진흥원 공고"""
    print("  [NIA] 한국지능정보사회진흥원 공고 크롤링...")
    try:
        url = "https://www.nia.or.kr/site/nia_kor/ex/bbs/List.do?cbIdx=82615"
        html = _fetch_url(url)
        results = []

        rows = re.findall(r'<a[^>]*href=["\']([^"\']*)["\'][^>]*>(.*?)</a>', html, re.DOTALL)
        for link, title_html in rows:
            title = re.sub(r"<[^>]+>", "", title_html).strip()
            if title and len(title) > 5 and _is_ai_related(title):
                full_url = link if link.startswith("http") else f"https://www.nia.or.kr{link}"
                results.append(GovProject(
                    title=title,
                    url=full_url,
                    source="NIA",
                    source_type="government",
                    category="지원사업",
                    tags=["NIA", "디지털", "지원사업"],
                ))
            if len(results) >= max_items:
                break
        print(f"  [NIA] {len(results)}개 AI 관련 항목")
        return results
    except Exception as e:
        print(f"  [NIA] 크롤링 실패: {e}")
        return []


def crawl_ai_news_claude(topic: str = "AI", count: int = 5) -> list[GovProject]:
    """Claude API로 최신 AI 뉴스/트렌드 토픽 생성"""
    print(f"  [Claude] 최신 AI 뉴스 토픽 생성... (주제: {topic})")
    try:
        import anthropic
        client = anthropic.Anthropic()

        prompt = f"""당신은 한국 AI 뉴스 전문 에디터입니다.
2026년 3월 현재 가장 핫한 AI 관련 뉴스/트렌드/정부사업 토픽 {count}개를 생성해주세요.

주제 범위: {topic}

토픽 유형:
- AI 업계 뉴스 (새 모델 출시, 기업 동향 등)
- 정부 AI 지원사업/공모전
- AI 도구/서비스 업데이트
- AI 정책/규제 변화
- AI 활용 사례

반드시 아래 JSON만 출력:
{{
  "topics": [
    {{
      "title": "한국어로 된 블로그 제목 (60자 이하)",
      "summary": "핵심 내용 3줄 요약",
      "category": "ai-news 또는 gov-projects 또는 ai-tools 또는 tutorials",
      "source_name": "출처 이름 (예: OpenAI 공식 블로그)",
      "source_url": "실제 출처 URL (알 수 있으면)",
      "source_type": "government 또는 news 또는 official 또는 paper",
      "difficulty": "beginner 또는 intermediate 또는 advanced",
      "tags": ["태그1", "태그2", "태그3"]
    }}
  ]
}}"""

        response = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=2048,
            messages=[{"role": "user", "content": prompt}],
        )

        text = response.content[0].text.strip()
        text = re.sub(r"```json\s*|```", "", text).strip()
        data = json.loads(text)
        topics = data.get("topics", [])

        results = []
        for t in topics[:count]:
            results.append(GovProject(
                title=t["title"],
                url=t.get("source_url", ""),
                source=t.get("source_name", "AI 브리핑"),
                source_type=t.get("source_type", "news"),
                summary=t.get("summary", ""),
                category=t.get("category", "ai-news"),
                tags=t.get("tags", []),
            ))

        print(f"  [Claude] {len(results)}개 토픽 생성")
        return results
    except Exception as e:
        print(f"  [Claude] 뉴스 토픽 생성 실패: {e}")
        return []


# ─── 통합 크롤러 ──────────────────────────

def crawl_all(max_per_source: int = 3) -> list[GovProject]:
    """모든 소스에서 AI 관련 정보 수집"""
    print("[크롤링] 정부사업 + AI 뉴스 수집 시작...")
    all_items = []

    # 정부 소스 크롤링
    all_items.extend(crawl_msit_news(max_per_source))
    all_items.extend(crawl_iitp_projects(max_per_source))
    all_items.extend(crawl_nia_projects(max_per_source))

    # Claude로 최신 토픽 보강
    all_items.extend(crawl_ai_news_claude(count=max_per_source))

    print(f"[크롤링] 총 {len(all_items)}개 항목 수집")
    return all_items


# ─── CLI ──────────────────────────────────

if __name__ == "__main__":
    from dotenv import load_dotenv
    load_dotenv()

    items = crawl_all(max_per_source=3)

    for i, item in enumerate(items, 1):
        print(f"\n[{i}] {item.title}")
        print(f"    소스: {item.source} ({item.source_type})")
        print(f"    URL: {item.url[:80]}..." if item.url else "    URL: 없음")
        print(f"    카테고리: {item.category}")
        print(f"    태그: {item.tags}")
        if item.summary:
            print(f"    요약: {item.summary[:100]}...")
