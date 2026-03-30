"""
daily_publish.py - 매일 10개 블로그 글 자동 발행

실행:
  python daily_publish.py              # 10개 발행 (기본)
  python daily_publish.py --count 5    # 5개만
  python daily_publish.py --dry-run    # 테스트 (배포 안함)

스케줄링:
  - GitHub Actions: .github/workflows/daily-posts.yml
  - Windows: daily_publish.bat → 작업 스케줄러
"""

import os
import sys
import json
import random
import time
from datetime import datetime, timedelta
from pathlib import Path

# 같은 디렉토리의 모듈 임포트
sys.path.insert(0, str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv()

import sero_blog

# ──────────────────────────────────────────────
# 토픽 풀: 카테고리별 주제 템플릿
# ──────────────────────────────────────────────
TOPIC_POOL = {
    "ai-news": [
        "이번 주 AI 업계 뉴스",
        "최신 AI 모델 출시 소식",
        "빅테크 AI 전략 변화",
        "AI 규제 정책 동향",
        "AI 스타트업 투자 트렌드",
        "생성형 AI 시장 전망",
        "AI 반도체 경쟁 현황",
        "오픈소스 AI 모델 동향",
        "AI 윤리와 안전성 논의",
        "국내 AI 기업 동향",
    ],
    "gov-projects": [
        "모두의 창업 프로젝트",
        "K-Startup 창업지원 사업",
        "정부 AI 바우처 지원사업",
        "디지털 뉴딜 AI 사업",
        "중소기업 AI 도입 지원",
        "AI 인재양성 정부사업",
        "지역 창업 지원 프로그램",
        "TIPS 프로그램 안내",
        "청년 창업 지원사업",
        "데이터 바우처 지원사업",
    ],
    "ai-tools": [
        "ChatGPT 활용법",
        "Claude AI 사용 가이드",
        "Midjourney 이미지 생성",
        "AI 코딩 도구 비교",
        "AI 영상 편집 도구",
        "AI 번역 도구 추천",
        "AI 문서 요약 도구",
        "AI 마케팅 자동화 도구",
        "AI 데이터 분석 도구",
        "무료 AI 도구 모음",
    ],
    "tutorials": [
        "AI 프롬프트 엔지니어링",
        "ChatGPT API 활용 튜토리얼",
        "AI로 블로그 자동화하기",
        "AI 이미지 생성 입문",
        "업무 자동화 AI 활용법",
        "AI로 데이터 분석하기",
        "AI 챗봇 만들기 가이드",
        "AI 음성 합성 활용법",
        "노코드 AI 앱 만들기",
        "AI로 영어 공부하기",
    ],
    "marketing": [
        "이메일 마케팅 자동화 전략",
        "SNS 마케팅 자동화 도구 비교",
        "AI 마케팅 자동화 플랫폼 추천",
        "퍼포먼스 마케팅 자동화 가이드",
        "CRM 마케팅 자동화 도입법",
        "콘텐츠 마케팅 자동화 워크플로우",
        "리타겟팅 광고 자동화 설정법",
        "AI 챗봇 마케팅 자동화",
        "마케팅 퍼널 자동화 구축",
        "SEO 자동화 도구 활용법",
    ],
}

# 발행 이력 추적 (중복 방지)
HISTORY_FILE = Path(__file__).parent / "publish_history.json"


def load_history() -> dict:
    """발행 이력 로드"""
    if HISTORY_FILE.exists():
        try:
            return json.loads(HISTORY_FILE.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {"published": [], "last_run": ""}


def save_history(history: dict):
    """발행 이력 저장"""
    # 최근 30일 이력만 보관
    cutoff = (datetime.now() - timedelta(days=30)).strftime("%Y-%m-%d")
    history["published"] = [
        p for p in history["published"]
        if p.get("date", "") >= cutoff
    ]
    HISTORY_FILE.write_text(
        json.dumps(history, ensure_ascii=False, indent=2),
        encoding="utf-8",
    )


def select_daily_topics(count: int = 10) -> list[dict]:
    """오늘 발행할 토픽 선택 (카테고리 분산 + 중복 방지)"""
    history = load_history()
    recent_titles = {p["title"] for p in history["published"]}

    # 카테고리별 배분: ai-news 2, gov-projects 2, ai-tools 2, tutorials 2, marketing 2
    distribution = {
        "ai-news": 2,
        "gov-projects": 2,
        "ai-tools": 2,
        "tutorials": 2,
        "marketing": 2,
    }

    # count에 맞게 비례 배분 조정
    if count != 10:
        total_ratio = sum(distribution.values())
        distribution = {
            k: max(1, round(v / total_ratio * count))
            for k, v in distribution.items()
        }
        # 합계 조정
        while sum(distribution.values()) > count:
            max_cat = max(distribution, key=distribution.get)
            distribution[max_cat] -= 1
        while sum(distribution.values()) < count:
            min_cat = min(distribution, key=distribution.get)
            distribution[min_cat] += 1

    topics = []
    for category, num in distribution.items():
        pool = TOPIC_POOL.get(category, [])
        # 최근 발행하지 않은 토픽 우선
        available = [t for t in pool if t not in recent_titles]
        if not available:
            available = pool  # 전부 발행했으면 리셋

        selected = random.sample(available, min(num, len(available)))
        for topic_title in selected:
            topics.append({
                "topic": topic_title,
                "category": category,
            })

    random.shuffle(topics)
    return topics[:count]


def run_daily(count: int = 10, dry_run: bool = False):
    """매일 실행: count개 블로그 글 생성 및 발행"""
    start = time.time()
    today = datetime.now().strftime("%Y-%m-%d")

    print("=" * 60)
    print(f"일일 자동 발행 시작")
    print(f"  날짜: {today}")
    print(f"  목표: {count}편")
    print(f"  모드: {'Dry-run' if dry_run else 'Full (배포 포함)'}")
    print("=" * 60)

    history = load_history()

    # 오늘 이미 발행한 수 확인
    today_published = [p for p in history["published"] if p.get("date") == today]
    if len(today_published) >= count:
        print(f"\n오늘 이미 {len(today_published)}편 발행 완료. 스킵합니다.")
        return

    remaining = count - len(today_published)
    print(f"  오늘 발행 완료: {len(today_published)}편 → 추가 {remaining}편 생성")

    # 토픽 선택
    daily_topics = select_daily_topics(remaining)
    print(f"\n선택된 토픽 ({len(daily_topics)}개):")
    for i, t in enumerate(daily_topics):
        print(f"  {i+1}. [{t['category']}] {t['topic']}")

    # K-Startup 최신 공고 먼저 크롤링 (gov-projects 카테고리에 사용)
    kstartup_topics = []
    if sero_blog.KSTARTUP_ENABLED:
        try:
            import kstartup_crawler
            anns = kstartup_crawler.crawl_recent(days=7, max_results=3)
            for ann in anns:
                kstartup_topics.append(sero_blog.TopicData(
                    title=ann.title,
                    category="gov-projects",
                    summary=f"마감: {ann.deadline} (D-{ann.d_day})",
                    source_name="K-Startup",
                    source_url=ann.url,
                    source_type="government",
                    tags=ann.tags,
                ))
        except Exception as e:
            print(f"  [K-Startup] 크롤링 실패: {e}")

    results = []
    kstartup_idx = 0

    for i, topic_info in enumerate(daily_topics):
        print(f"\n{'─' * 50}")
        print(f"[{i+1}/{len(daily_topics)}] {topic_info['topic']}")
        print(f"{'─' * 50}")

        try:
            # gov-projects 카테고리이고 K-Startup 데이터가 있으면 실제 데이터 사용
            if topic_info["category"] == "gov-projects" and kstartup_idx < len(kstartup_topics):
                topic_data = kstartup_topics[kstartup_idx]
                kstartup_idx += 1
                print(f"  → K-Startup 실제 데이터 사용: {topic_data.title}")
            else:
                # Claude로 토픽 상세 생성
                topic_data = sero_blog.TopicData(
                    title=topic_info["topic"],
                    category=topic_info["category"],
                    summary="",
                    difficulty="beginner",
                )

            # 글 생성
            post = sero_blog.generate_blog_post(topic_data)
            post.published = True

            # SEO 교정
            post.content = sero_blog.review_and_polish(post)

            # SEO 감사
            post = sero_blog.run_seo_audit(post)

            # MDX 파일 생성
            filepath = sero_blog.create_mdx_file(post)

            # 배포
            deployed = False
            if not dry_run and filepath:
                deployed = sero_blog.deploy(filepath)

            results.append({
                "title": post.title,
                "category": post.category,
                "seo_score": post.seo_score,
                "deployed": deployed,
                "file": filepath.name if filepath else "",
            })

            # 이력 기록
            history["published"].append({
                "title": topic_info["topic"],
                "category": topic_info["category"],
                "date": today,
                "slug": filepath.stem if filepath else "",
            })
            save_history(history)

        except Exception as e:
            print(f"  [오류] 생성 실패: {e}")
            print("  → 다음 글로 넘어갑니다.")

        # API 과부하 방지 (3초 대기)
        if i < len(daily_topics) - 1:
            print("  다음 글 준비 중... (3초)")
            time.sleep(3)

    # 최종 결과
    duration = int(time.time() - start)
    history["last_run"] = f"{today} ({len(results)}/{len(daily_topics)} 성공, {duration}초)"
    save_history(history)

    print("\n" + "=" * 60)
    print(f"일일 발행 완료! ({duration}초)")
    print(f"  성공: {len(results)}/{len(daily_topics)}편")
    for r in results:
        status = "LIVE" if r["deployed"] else "FILE"
        print(f"  [{status}] {r['title']} (SEO: {r['seo_score']:.0f})")
    print("=" * 60)

    return results


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="매일 10개 블로그 글 자동 발행")
    parser.add_argument("--count", type=int, default=10, help="발행할 글 수 (기본: 10)")
    parser.add_argument("--dry-run", action="store_true", help="테스트 모드 (배포 안함)")
    args = parser.parse_args()

    run_daily(count=args.count, dry_run=args.dry_run)
