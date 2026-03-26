// ============================================
// 사이트 설정 — AI 브리핑
// ============================================

export const siteConfig = {
  // 기본 정보
  name: "AI 브리핑",
  description:
    "AI 트렌드, 정부 AI 사업, 실전 활용법을 누구나 이해할 수 있게 정리합니다",
  url: "https://coupang-blog-rho.vercel.app",
  author: "AI 브리핑",
  locale: "ko_KR",

  // SEO
  defaultTitle: "AI 브리핑 | AI 뉴스 · 정부사업 · 활용 가이드",
  titleTemplate: "%s | AI 브리핑",

  // 소셜
  social: {
    instagram: "",
    twitter: "",
  },

  // 카테고리
  categories: [
    { slug: "ai-news", name: "AI 뉴스", emoji: "🤖" },
    { slug: "gov-projects", name: "정부사업", emoji: "🏛️" },
    { slug: "ai-tools", name: "AI 도구", emoji: "🛠️" },
    { slug: "tutorials", name: "튜토리얼", emoji: "📚" },
  ],

  // 네비게이션
  nav: [
    { href: "/", label: "홈" },
    { href: "/posts", label: "전체 글" },
    { href: "/categories/ai-news", label: "AI 뉴스" },
    { href: "/categories/gov-projects", label: "정부사업" },
    { href: "/categories/ai-tools", label: "AI 도구" },
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
    disclaimer:
      "이 포스팅은 쿠팡 파트너스 활동의 일환으로, 이에 따른 일정액의 수수료를 제공받습니다.",
  },

  // Google Analytics
  analytics: {
    gaId: "", // G-XXXXXXXXXX
  },

  // 법적 고지
  disclaimer:
    "본 블로그의 콘텐츠는 공공 데이터와 AI를 활용하여 작성되었으며, 정확한 정보는 원문 출처를 확인해주세요.",
};

// 카테고리 찾기
export function getCategory(slug: string) {
  return siteConfig.categories.find((c) => c.slug === slug);
}
