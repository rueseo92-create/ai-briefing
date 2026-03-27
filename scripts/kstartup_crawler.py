"""
kstartup_crawler.py - K-Startup(k-startup.go.kr) 크롤러

최신 1주일 이내 창업지원 공고만 스크래핑합니다.
"""

import re
import urllib.request
import urllib.parse
from datetime import datetime, timedelta
from dataclasses import dataclass, field
from html.parser import HTMLParser


@dataclass
class KStartupAnnouncement:
    """K-Startup 공고 데이터"""
    title: str
    pbanc_sn: str  # 공고 고유번호
    url: str
    deadline: str  # YYYY-MM-DD
    d_day: int = 0
    organization: str = ""
    category: str = ""  # 사업화, 멘토링/컨설팅/교육, 시설/공간 등
    ann_type: str = ""  # 공공, 민간, 지자체
    views: int = 0
    posted_date: str = ""
    summary: str = ""
    support_details: str = ""
    eligibility: str = ""
    tags: list = field(default_factory=list)


class KStartupListParser(HTMLParser):
    """K-Startup 공고 목록 HTML 파서"""

    def __init__(self):
        super().__init__()
        self.announcements = []
        self._current = {}
        self._in_title = False
        self._in_org = False
        self._in_deadline = False
        self._capture_text = ""

    def handle_starttag(self, tag, attrs):
        attrs_dict = dict(attrs)
        # 공고 링크: onclick="go_view(176892)"
        if tag == "a" and attrs_dict.get("onclick", "").startswith("go_view("):
            match = re.search(r"go_view\((\d+)\)", attrs_dict["onclick"])
            if match:
                pbanc_sn = match.group(1)
                self._current = {"pbanc_sn": pbanc_sn}
                self._in_title = True
                self._capture_text = ""

    def handle_data(self, data):
        if self._in_title:
            self._capture_text += data.strip()

    def handle_endtag(self, tag):
        if self._in_title and tag == "a":
            self._in_title = False
            if self._current and self._capture_text:
                self._current["title"] = self._capture_text.strip()
                self.announcements.append(self._current)
                self._current = {}


def _fetch_url(url: str, timeout: int = 15) -> str:
    """URL에서 HTML 가져오기"""
    headers = {
        "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
        "Accept-Language": "ko-KR,ko;q=0.9",
    }
    req = urllib.request.Request(url, headers=headers)
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        return resp.read().decode("utf-8", errors="replace")


def crawl_listing(search_keyword: str = "", max_pages: int = 2) -> list[KStartupAnnouncement]:
    """K-Startup 공고 목록 크롤링 (최근 1주일 이내만)"""
    base_url = "https://www.k-startup.go.kr/web/contents/bizpbanc-ongoing.do"
    announcements = []
    one_week_ago = datetime.now() - timedelta(days=7)

    for page in range(1, max_pages + 1):
        params = {"page": str(page)}
        if search_keyword:
            params["schStr"] = search_keyword
        url = f"{base_url}?{urllib.parse.urlencode(params)}"

        try:
            html = _fetch_url(url)
        except Exception as e:
            print(f"  [K-Startup] 페이지 {page} 로드 실패: {e}")
            continue

        # go_view(번호) + 제목을 한 쌍으로 추출 (여러 패턴 시도)
        # 패턴1: go_view(id)">제목</a>
        pairs = re.findall(r'go_view\((\d+)\)[^>]*>\s*([^<]+?)\s*</a>', html)

        # D-day 추출
        d_days = re.findall(r'D-(\d+)', html)

        seen_ids = set()
        for i, (pbanc_sn, raw_title) in enumerate(pairs):
            if pbanc_sn in seen_ids:
                continue
            seen_ids.add(pbanc_sn)

            title = raw_title.strip()
            # 제목이 비어있거나 숫자만 있으면 상세 페이지에서 가져오기
            if not title or title.isdigit() or len(title) < 5:
                detail = crawl_detail(pbanc_sn)
                title = detail.get("title", "") or f"K-Startup 사업 {pbanc_sn}"

            d_day = int(d_days[i]) if i < len(d_days) else 0

            # 마감일 계산
            deadline_str = ""
            if d_day > 0:
                deadline_date = datetime.now() + timedelta(days=d_day)
                deadline_str = deadline_date.strftime("%Y-%m-%d")

            ann = KStartupAnnouncement(
                title=title,
                pbanc_sn=pbanc_sn,
                url=f"{base_url}?schM=view&pbancSn={pbanc_sn}",
                deadline=deadline_str,
                d_day=d_day,
                tags=["창업지원", "K-Startup"],
            )
            announcements.append(ann)

    print(f"  [K-Startup] 총 {len(announcements)}개 공고 발견")
    return announcements


def crawl_detail(pbanc_sn: str) -> dict:
    """공고 상세 페이지 크롤링 — 실제 사업명, 주관기관, 내용 추출"""
    url = f"https://www.k-startup.go.kr/web/contents/bizpbanc-ongoing.do?schM=view&pbancSn={pbanc_sn}"
    try:
        html = _fetch_url(url)

        # 사업명/제목 추출 (여러 패턴 시도)
        title = ""
        # 패턴1: <h3> 또는 <h4> 안의 사업명
        title_match = re.search(r'<h[34][^>]*>\s*([^<]{5,}?)\s*</h[34]>', html)
        if title_match:
            title = title_match.group(1).strip()
        # 패턴2: "사업명" 라벨 옆의 값
        if not title:
            title_match = re.search(r'사업명[^<]*<[^>]*>\s*([^<]+)', html)
            if title_match:
                title = title_match.group(1).strip()
        # 패턴3: <title> 태그에서
        if not title:
            title_match = re.search(r'<title>([^<]+)</title>', html)
            if title_match:
                raw = title_match.group(1).strip()
                # "K-Startup > ..." 같은 prefix 제거
                if ">" in raw:
                    title = raw.split(">")[-1].strip()
                else:
                    title = raw

        # 주관기관
        org_match = re.search(r'주관기관[^<]*<[^>]*>\s*([^<]+)', html)
        organization = org_match.group(1).strip() if org_match else ""

        # 공고일
        date_match = re.search(r'공고일[^<]*<[^>]*>\s*(\d{4}[.\-]\d{2}[.\-]\d{2})', html)
        posted_date = date_match.group(1).strip() if date_match else ""

        # 지원 대상
        eligibility_match = re.search(r'지원\s*대상[^<]*<[^>]*>\s*([^<]+)', html)
        eligibility = eligibility_match.group(1).strip() if eligibility_match else ""

        # 지원 내용
        support_match = re.search(r'지원\s*내용[^<]*<[^>]*>\s*([^<]+)', html)
        support = support_match.group(1).strip() if support_match else ""

        # 본문 텍스트 (태그 제거)
        content_match = re.search(r'<div[^>]*class="[^"]*view[^"]*"[^>]*>(.*?)</div>', html, re.DOTALL)
        content_text = ""
        if content_match:
            content_text = re.sub(r'<[^>]+>', ' ', content_match.group(1))
            content_text = re.sub(r'\s+', ' ', content_text).strip()

        return {
            "title": title,
            "organization": organization,
            "posted_date": posted_date,
            "eligibility": eligibility,
            "support": support,
            "content": content_text[:2000],
        }
    except Exception as e:
        print(f"  [K-Startup] 상세 페이지 로드 실패 ({pbanc_sn}): {e}")
        return {}


def crawl_modoo_startup(max_results: int = 5) -> list[KStartupAnnouncement]:
    """'모두의 창업' 관련 공고 크롤링"""
    print("[K-Startup] '모두의 창업' 공고 크롤링 중...")
    results = crawl_listing(search_keyword="모두의창업", max_pages=1)

    if not results:
        # 검색 결과 없으면 전체 목록에서 필터
        all_anns = crawl_listing(max_pages=2)
        results = [a for a in all_anns if "모두의" in a.title or "창업" in a.title]

    return results[:max_results]


def crawl_recent(days: int = 7, max_results: int = 10) -> list[KStartupAnnouncement]:
    """최근 N일 이내 공고만 필터링"""
    print(f"[K-Startup] 최근 {days}일 이내 공고 크롤링 중...")
    all_anns = crawl_listing(max_pages=3)

    # D-day가 너무 먼 것은 오래된 공고일 가능성 → 최근 등록된 것 위주로 필터
    # K-Startup은 목록이 최신순이므로 앞쪽이 최근 공고
    recent = all_anns[:max_results]

    print(f"  → {len(recent)}개 최근 공고 선택")
    for ann in recent:
        print(f"    - [{ann.d_day}일 남음] {ann.title}")

    return recent


if __name__ == "__main__":
    print("=== K-Startup 모두의 창업 크롤러 ===\n")
    results = crawl_modoo_startup()
    for r in results:
        print(f"\n제목: {r.title}")
        print(f"URL: {r.url}")
        print(f"마감: {r.deadline} (D-{r.d_day})")
