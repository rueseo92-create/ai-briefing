// ============================================
// 사이트 설정 — AI 브리핑
// ============================================

export const siteConfig = {
  // 기본 정보
  name: "AI 브리핑",
  description:
    "AI 트렌드, AI 부업·자동화 수익, 실전 활용법을 누구나 이해할 수 있게 정리합니다",
  url: "https://seroai.xyz",
  author: "AI 브리핑",
  locale: "ko_KR",

  // SEO
  defaultTitle: "AI 브리핑 | AI 뉴스 · AI 부업 · 활용 가이드",
  titleTemplate: "%s | AI 브리핑",

  // 소셜
  social: {
    instagram: "",
    twitter: "",
  },

  // 카테고리
  categories: [
    { slug: "ai-news", name: "AI 뉴스", emoji: "🤖" },
    { slug: "side-hustle", name: "AI 부업", emoji: "💰" },
    { slug: "ai-tools", name: "AI 도구", emoji: "🛠️" },
    { slug: "tutorials", name: "튜토리얼", emoji: "📚" },
    { slug: "marketing", name: "마케팅 자동화", emoji: "📈" },
  ],

  // 네비게이션
  nav: [
    { href: "/", label: "홈" },
    { href: "/posts", label: "전체 글" },
    { href: "/categories/ai-news", label: "AI 뉴스" },
    { href: "/categories/side-hustle", label: "AI 부업" },
    { href: "/categories/ai-tools", label: "AI 도구" },
    { href: "/categories/marketing", label: "마케팅 자동화" },
    { href: "/business", label: "사업 소개" },
    { href: "/about", label: "소개" },
  ],

  // 쿠팡 파트너스
  coupang: {
    enabled: true,
    trackingCode: "AF9905627",
    // 동적 배너 광고 ID
    ads: {
      postBottom: { id: 838592, template: "carousel" as const, width: "680", height: "140" },
      sidebar: { id: 838592, template: "card" as const, width: "300", height: "250" },
      postMid: { id: 838592, template: "banner" as const, width: "680", height: "100" },
      homeTop: { id: 838592, template: "carousel" as const, width: "680", height: "140" },
    },
    // 카테고리별 쿠팡 실제 인기 상품 키워드
    productKeywords: {
      "ai-news": [
        "챗GPT 4.0 활용법 도서",
        "삼성 갤럭시북4 프로",
        "로지텍 MX Keys S 키보드",
        "에어팟 프로 2세대",
      ],
      "side-hustle": [
        "1인 창업 도서",
        "디지털 노마드 도서",
        "LG 그램 노트북",
        "로지텍 웹캠 C920",
      ],
      "ai-tools": [
        "LG 울트라와이드 모니터 34인치",
        "로지텍 MX Master 3S 마우스",
        "삼성 T7 외장SSD 1TB",
        "아이패드 에어 M2",
      ],
      tutorials: [
        "혼자 공부하는 파이썬",
        "맥북 에어 M3",
        "카멜 모니터암 거치대",
        "앱코 해커 기계식 키보드",
      ],
      marketing: [
        "마케팅 자동화 도서",
        "디지털 마케팅 도서",
        "삼성 갤럭시탭 S9",
        "로지텍 MX Keys S 키보드",
      ],
    } as Record<string, string[]>,
    // 태그 → 상품 키워드 매핑 (글 내용과 연관된 상품)
    tagProductMap: {
      "ChatGPT": "챗GPT 활용법 도서",
      "Claude": "AI 프롬프트 엔지니어링 도서",
      "코딩": "혼자 공부하는 파이썬",
      "자동화": "업무 자동화 도서",
      "번역": "파파고 vs 구글번역 도서",
      "이미지": "아이패드 에어 M2",
      "반도체": "반도체 투자 도서",
      "채용": "개발자 취업 도서",
      "창업": "린 스타트업 도서",
      "노트북": "삼성 갤럭시북4 프로",
      "GPT": "GPT-4 API 활용 도서",
      "AI": "AI 2024 트렌드 도서",
      "마케팅": "디지털 마케팅 도서",
      "이메일": "이메일 마케팅 도서",
      "CRM": "CRM 마케팅 자동화 도서",
      "SNS": "SNS 마케팅 도서",
      "광고": "구글 광고 도서",
    } as Record<string, string>,
    disclaimer:
      "이 포스팅은 쿠팡 파트너스 활동의 일환으로, 이에 따른 일정액의 수수료를 제공받습니다.",
  },

  // Google Analytics
  analytics: {
    gaId: "G-01E31GWTCD",
  },

  // 법적 고지
  disclaimer:
    "본 블로그의 콘텐츠는 공공 데이터와 AI를 활용하여 작성되었으며, 정확한 정보는 원문 출처를 확인해주세요.",
};

// 카테고리 찾기
export function getCategory(slug: string) {
  return siteConfig.categories.find((c) => c.slug === slug);
}
