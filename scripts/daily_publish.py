"""
daily_publish.py - 시간대별 자동 발행 + QC

실행:
  python daily_publish.py                    # 현재 시간 슬롯에 맞게 발행
  python daily_publish.py --slot morning     # 오전 슬롯 강제 실행
  python daily_publish.py --slot all         # 전체 슬롯 (10개) 한번에 발행
  python daily_publish.py --count 5          # 수동: 5개 발행 (슬롯 무시)
  python daily_publish.py --qc              # 최근 포스트 QC만 실행
  python daily_publish.py --dry-run         # 테스트 (배포 안함)

스케줄링:
  - GitHub Actions: .github/workflows/daily-posts.yml (1일 4회)
  - Windows: daily_publish.bat -> 작업 스케줄러
"""

import os
import sys
import json
import re
import random
import time
from datetime import datetime, timedelta, timezone
from pathlib import Path

# 같은 디렉토리의 모듈 임포트
sys.path.insert(0, str(Path(__file__).parent))

from dotenv import load_dotenv
load_dotenv()

import sero_blog

# ──────────────────────────────────────────────
# 시간대별 발행 슬롯 (한국시간 기준)
# ──────────────────────────────────────────────
# 하루 총 10편: 4개 슬롯에 분산 발행
# 검색 트래픽 패턴에 맞춰 카테고리+검색 의도 배분
SLOT_CONFIG = {
    "morning": {
        "hours": (6, 10),       # 06:00~09:59 KST
        "count": 3,
        "distribution": {"ai-news": 2, "marketing": 1},
        "seo_angle": "최신 뉴스, 트렌드, 속보",
        "label": "오전 (07:00)",
    },
    "lunch": {
        "hours": (11, 14),      # 11:00~13:59 KST
        "count": 2,
        "distribution": {"ai-tools": 1, "side-hustle": 1},
        "seo_angle": "사용법, 활용 가이드, 추천",
        "label": "점심 (12:30)",
    },
    "evening": {
        "hours": (17, 20),      # 17:00~19:59 KST
        "count": 3,
        "distribution": {"marketing": 1, "side-hustle": 1, "ai-tools": 1},
        "seo_angle": "비교 분석, 리뷰, 실전 팁",
        "label": "저녁 (18:00)",
    },
    "night": {
        "hours": (20, 24),      # 20:00~23:59 KST
        "count": 2,
        "distribution": {"side-hustle": 2},
        "seo_angle": "심층 분석, 부업 가이드, 수익화 전략",
        "label": "야간 (21:30)",
    },
}

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
    "side-hustle": [
        "AI 부업으로 월 100만원 만들기",
        "ChatGPT로 수익 내는 방법",
        "AI 자동화 부업 아이디어",
        "디지털 노마드 수입원 만들기",
        "AI 콘텐츠 판매 부업",
        "프리랜서 AI 활용 수익화",
        "AI 번역 부업 시작하기",
        "자동화 수익 파이프라인 구축",
        "AI 이미지 판매 부업",
        "패시브 인컴 AI 활용법",
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

# ──────────────────────────────────────────────
# SEO 트래픽 부스트: 검색량 높은 키워드 수식어
# ──────────────────────────────────────────────
SEO_MODIFIERS = {
    "ai-news": ["속보", "이번 주", "최신", "긴급", "단독"],
    "side-hustle": ["월 100만원", "무자본", "초보자", "수익 인증", "자동화"],
    "ai-tools": ["무료", "추천 TOP", "직접 써보니", "비교", "초보자용"],
    "marketing": ["ROI 200%", "자동화 비법", "매출 2배", "실전 사례", "무료 도구"],
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


def get_kst_now() -> datetime:
    """현재 한국시간 반환"""
    KST = timezone(timedelta(hours=9))
    return datetime.now(KST)


def detect_slot() -> str:
    """현재 한국시간 기준으로 발행 슬롯 자동 감지"""
    kst_hour = get_kst_now().hour
    for slot_name, config in SLOT_CONFIG.items():
        start, end = config["hours"]
        if start <= kst_hour < end:
            return slot_name
    # 매칭되는 슬롯 없으면 morning 폴백
    return "morning"


def select_daily_topics(count: int = 10, slot: str = None) -> list[dict]:
    """오늘 발행할 토픽 선택 (슬롯별 배분 + 중복 방지)"""
    history = load_history()
    recent_titles = {p["title"] for p in history["published"]}

    # 슬롯 지정 시 해당 슬롯 배분, 아니면 균등 배분
    if slot and slot in SLOT_CONFIG:
        distribution = dict(SLOT_CONFIG[slot]["distribution"])
    else:
        distribution = {
            "ai-news": 3,
            "side-hustle": 3,
            "ai-tools": 2,
            "marketing": 2,
        }
        # count에 맞게 비례 배분 조정
        if count != 10:
            total_ratio = sum(distribution.values())
            distribution = {
                k: max(1, round(v / total_ratio * count))
                for k, v in distribution.items()
            }
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

        # SEO 수식어 부스트
        modifiers = SEO_MODIFIERS.get(category, [])
        for topic_title in selected:
            modifier = random.choice(modifiers) if modifiers else ""
            topics.append({
                "topic": topic_title,
                "category": category,
                "seo_modifier": modifier,
            })

    random.shuffle(topics)
    return topics[:count]


# ──────────────────────────────────────────────
# QC (품질 검사)
# ──────────────────────────────────────────────
def run_qc(days: int = 7) -> list[dict]:
    """최근 포스트 품질 검사"""
    posts_dir = Path(__file__).parent.parent / "content" / "posts"
    cutoff = (datetime.now() - timedelta(days=days)).strftime("%Y-%m-%d")

    issues = []
    checked = 0
    scores = []

    print("=" * 60)
    print(f"포스트 품질 검사 (QC)")
    print(f"  대상: 최근 {days}일간 발행 포스트")
    print("=" * 60)

    if not posts_dir.exists():
        print("  포스트 디렉토리 없음")
        return issues

    for f in sorted(posts_dir.glob("*.mdx"), reverse=True):
        date_str = f.stem[:10]
        if date_str < cutoff:
            break

        checked += 1
        content = f.read_text(encoding="utf-8")
        parts = content.split("---", 2)
        if len(parts) < 3:
            issues.append({"file": f.name, "issue": "프론트매터 파싱 실패", "severity": "error"})
            continue

        fm = parts[1]
        body = parts[2]
        body_clean = re.sub(r"\s", "", body)

        checks_passed = 0
        checks_total = 9

        # 1. 본문 길이
        if len(body_clean) >= 1000:
            checks_passed += 1
        else:
            sev = "error" if len(body_clean) < 500 else "warning"
            issues.append({"file": f.name, "issue": f"본문 짧음 ({len(body_clean)}자)", "severity": sev})

        # 2. H2 구조
        h2_count = len(re.findall(r"^## ", body, re.MULTILINE))
        if h2_count >= 3:
            checks_passed += 1
        else:
            issues.append({"file": f.name, "issue": f"H2 부족 ({h2_count}개)", "severity": "warning"})

        # 3. H3 존재
        h3_count = len(re.findall(r"^### ", body, re.MULTILINE))
        if h3_count >= 1:
            checks_passed += 1
        else:
            issues.append({"file": f.name, "issue": "H3 없음", "severity": "info"})

        # 4. FAQ 섹션
        has_faq = any(kw in body for kw in ["FAQ", "자주 묻는", "Q.", "Q:"])
        if has_faq:
            checks_passed += 1
        else:
            issues.append({"file": f.name, "issue": "FAQ 섹션 없음", "severity": "warning"})

        # 5. 내부 링크
        has_internal = "](/posts/" in body or "](/categories/" in body
        if has_internal:
            checks_passed += 1
        else:
            issues.append({"file": f.name, "issue": "내부 링크 없음 (SEO 손실)", "severity": "warning"})

        # 6. 제목 길이
        title_m = re.search(r'title:\s*"(.+?)"', fm)
        title_ok = title_m and len(title_m.group(1)) <= 60
        if title_ok:
            checks_passed += 1
        elif title_m:
            issues.append({"file": f.name, "issue": f"제목 초과 ({len(title_m.group(1))}자)", "severity": "warning"})

        # 7. description 길이
        desc_m = re.search(r'description:\s*"(.+?)"', fm)
        desc_ok = desc_m and 50 <= len(desc_m.group(1)) <= 155
        if desc_ok:
            checks_passed += 1
        elif desc_m:
            issues.append({"file": f.name, "issue": f"설명 길이 이상 ({len(desc_m.group(1))}자)", "severity": "info"})

        # 8. 태그 수
        tags_m = re.search(r'tags:\s*\[(.+?)\]', fm)
        tags_ok = tags_m and len(tags_m.group(1).split(",")) >= 3
        if tags_ok:
            checks_passed += 1

        # 9. 표 존재
        has_table = bool(re.search(r"\|.+\|.+\|", body))
        if has_table:
            checks_passed += 1
        else:
            issues.append({"file": f.name, "issue": "표(Table) 없음", "severity": "info"})

        score = round(checks_passed / checks_total * 100)
        scores.append({"file": f.name, "score": score})

    # 결과 출력
    print(f"\n검사 완료: {checked}개 포스트")

    if scores:
        avg = sum(s["score"] for s in scores) / len(scores)
        print(f"평균 품질 점수: {avg:.0f}/100")

        low = [s for s in scores if s["score"] < 70]
        if low:
            print(f"\n저품질 포스트 ({len(low)}개):")
            for s in low:
                print(f"  [{s['score']}점] {s['file']}")

    if issues:
        errors = sum(1 for i in issues if i["severity"] == "error")
        warns = sum(1 for i in issues if i["severity"] == "warning")
        infos = sum(1 for i in issues if i["severity"] == "info")
        print(f"\n이슈: {errors} errors, {warns} warnings, {infos} info")
        for iss in issues:
            icon = {"error": "X", "warning": "!", "info": "i"}.get(iss["severity"], "?")
            print(f"  [{icon}] {iss['file'][:40]} - {iss['issue']}")
    else:
        print("\n모든 포스트 QC 통과!")

    print("=" * 60)
    return issues


# ──────────────────────────────────────────────
# 메인 발행 로직
# ──────────────────────────────────────────────
def run_daily(slot: str = "auto", count: int = None, dry_run: bool = False):
    """슬롯 기반 자동 발행"""
    start = time.time()
    today = datetime.now().strftime("%Y-%m-%d")

    # 슬롯 결정
    if slot == "auto":
        slot = detect_slot()

    # 전체 슬롯 순차 실행
    if slot == "all":
        all_results = []
        for s in SLOT_CONFIG:
            results = run_daily(slot=s, dry_run=dry_run)
            if results:
                all_results.extend(results)
        return all_results

    slot_config = SLOT_CONFIG.get(slot)
    effective_count = count or (slot_config["count"] if slot_config else 3)

    print("=" * 60)
    print(f"자동 발행 시작")
    print(f"  날짜: {today}")
    print(f"  슬롯: {slot_config['label'] if slot_config else slot}")
    print(f"  목표: {effective_count}편")
    if slot_config:
        print(f"  SEO 각도: {slot_config['seo_angle']}")
    print(f"  모드: {'Dry-run' if dry_run else 'Full (배포 포함)'}")
    print("=" * 60)

    history = load_history()

    # 오늘 이 슬롯에서 이미 발행한 수 확인
    today_slot_published = [
        p for p in history["published"]
        if p.get("date") == today and p.get("slot", "") == slot
    ]
    if len(today_slot_published) >= effective_count:
        print(f"\n[{slot}] 슬롯에서 이미 {len(today_slot_published)}편 발행 완료. 스킵합니다.")
        return []

    remaining = effective_count - len(today_slot_published)
    print(f"  이 슬롯 발행: {len(today_slot_published)}편 완료 -> 추가 {remaining}편 생성")

    # 토픽 선택 (슬롯 기반)
    daily_topics = select_daily_topics(remaining, slot=slot if slot_config else None)
    print(f"\n선택된 토픽 ({len(daily_topics)}개):")
    for i, t in enumerate(daily_topics):
        mod = f" [{t.get('seo_modifier', '')}]" if t.get("seo_modifier") else ""
        print(f"  {i+1}. [{t['category']}] {t['topic']}{mod}")

    # K-Startup 최신 공고 크롤링 (side-hustle 카테고리에 사용)
    kstartup_topics = []
    if sero_blog.KSTARTUP_ENABLED:
        try:
            import kstartup_crawler
            anns = kstartup_crawler.crawl_recent(days=7, max_results=3)
            for ann in anns:
                kstartup_topics.append(sero_blog.TopicData(
                    title=ann.title,
                    category="side-hustle",
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
            # side-hustle + K-Startup 실제 데이터 우선
            if topic_info["category"] == "side-hustle" and kstartup_idx < len(kstartup_topics):
                topic_data = kstartup_topics[kstartup_idx]
                kstartup_idx += 1
                print(f"  -> K-Startup 실제 데이터 사용: {topic_data.title}")
            else:
                # SEO 수식어를 summary에 힌트로 전달
                seo_hint = topic_info.get("seo_modifier", "")
                topic_data = sero_blog.TopicData(
                    title=topic_info["topic"],
                    category=topic_info["category"],
                    summary=f"SEO 키워드 힌트: {seo_hint}" if seo_hint else "",
                    difficulty="beginner",
                )

            # 글 생성 + 프로그래밍 품질 보정 (단일 API 호출)
            post = sero_blog.generate_blog_post(topic_data)
            post.published = True

            # SEO 감사 (API 호출 없음)
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

            # 이력 기록 (슬롯 정보 포함)
            history["published"].append({
                "title": topic_info["topic"],
                "category": topic_info["category"],
                "date": today,
                "slot": slot,
                "slug": filepath.stem if filepath else "",
            })
            save_history(history)

        except Exception as e:
            print(f"  [오류] 생성 실패: {e}")
            print("  -> 다음 글로 넘어갑니다.")

        # API 과부하 방지 (3초 대기)
        if i < len(daily_topics) - 1:
            print("  다음 글 준비 중... (3초)")
            time.sleep(3)

    # 최종 결과
    duration = int(time.time() - start)
    history["last_run"] = f"{today} [{slot}] ({len(results)}/{len(daily_topics)} 성공, {duration}초)"
    save_history(history)

    print("\n" + "=" * 60)
    print(f"발행 완료! [{slot}] ({duration}초)")
    print(f"  성공: {len(results)}/{len(daily_topics)}편")
    for r in results:
        status = "LIVE" if r["deployed"] else "FILE"
        print(f"  [{status}] {r['title']} (SEO: {r['seo_score']:.0f})")
    print("=" * 60)

    return results


if __name__ == "__main__":
    import argparse

    parser = argparse.ArgumentParser(description="시간대별 자동 발행 + QC")
    parser.add_argument("--slot", type=str, default="auto",
                        choices=["auto", "morning", "lunch", "evening", "night", "all"],
                        help="발행 슬롯 (기본: auto = 현재 시간 감지)")
    parser.add_argument("--count", type=int, default=None,
                        help="발행 수 (슬롯 설정 덮어씀)")
    parser.add_argument("--qc", action="store_true",
                        help="QC만 실행 (발행 안함)")
    parser.add_argument("--qc-days", type=int, default=7,
                        help="QC 검사 범위 일수 (기본: 7)")
    parser.add_argument("--dry-run", action="store_true",
                        help="테스트 모드 (배포 안함)")
    args = parser.parse_args()

    if args.qc:
        run_qc(days=args.qc_days)
    else:
        run_daily(slot=args.slot, count=args.count, dry_run=args.dry_run)
