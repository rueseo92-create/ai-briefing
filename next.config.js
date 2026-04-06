/** @type {import('next').NextConfig} */
const nextConfig = {
  trailingSlash: false,

  images: {
    remotePatterns: [
      { protocol: "https", hostname: "*.unsplash.com" },
      { protocol: "https", hostname: "images.unsplash.com" },
    ],
  },

  output: "standalone",

  async headers() {
    return [
      {
        source: "/(.*)",
        headers: [
          { key: "X-Content-Type-Options", value: "nosniff" },
          { key: "X-Frame-Options", value: "DENY" },
          { key: "X-XSS-Protection", value: "1; mode=block" },
          { key: "Referrer-Policy", value: "strict-origin-when-cross-origin" },
          { key: "Permissions-Policy", value: "camera=(), microphone=(), geolocation=()" },
        ],
      },
      {
        source: "/(.*)\\.(js|css|woff2|png|jpg|svg|ico)",
        headers: [
          { key: "Cache-Control", value: "public, max-age=31536000, immutable" },
        ],
      },
      {
        source: "/manifest.json",
        headers: [
          { key: "Cache-Control", value: "public, max-age=86400" },
        ],
      },
    ];
  },

  async redirects() {
    // 삭제된 포스트 slug → /posts 로 301 리디렉션 (Google 404 해소)
    const deletedSlugs = [
      "2024-big-tech-ai-strategy-changes",
      "2026-ai-chip-war-leader",
      "2026-k-startup-ai-success-guide",
      "ai-automation-beginner-guide",
      "ai-blogger-government-subsidy-guide",
      "ai-data-analysis-tools-top5",
      "ai-english-study-methods-guide",
      "ai-ethics-safety-trends-2024",
      "ai-graduate-school-funding-deadline",
      "ai-image-generation-guide",
      "ai-startup-funding-2026-guide",
      "ai-startup-funding-deadline",
      "ai-startup-funding-deadline-today",
      "ai-startup-funding-guide-2026",
      "ai-startup-investment-surge-reasons",
      "ai-voucher-deadline-application-guide",
      "best-ai-translation-tools-2024",
      "chatgpt-plus-complete-transformation",
      "data-voucher-application-guide",
      "deadline-ai-startup-funding-guide",
      "free-ai-tools-2024",
      "government-ai-automation-support-programs",
      "government-ai-startup-funding-success",
      "government-digital-content-support-deadline",
      "government-project-application-guide",
      "gpt-5-vs-claude-opus-comparison",
      "k-ai-global-hub-2026-funding",
      "k-ai-global-hub-funding",
      "k-chips-2-government-ai-project",
      "manufacturing-ai-subsidy-guide-2026",
      "modoo-startup-project-2026-guide",
      "naver-clovax-3-multimodal-ai",
      "naver-kakao-ai-hiring-guide",
      "openai-gpt5-official-release",
      "samsung-lg-ai-chip-competition",
      "small-business-ai-funding-2026",
      "small-business-ai-marketing-support",
    ];

    const postRedirects = deletedSlugs.map((slug) => ({
      source: `/posts/${slug}`,
      destination: "/posts",
      permanent: true,
    }));

    // 삭제된 다국어(zh/ja/es) 포스트 경로도 리디렉션
    const deletedLocaleRedirects = [
      { source: "/zh/:path*", destination: "/", permanent: true },
      { source: "/ja/:path*", destination: "/", permanent: true },
      { source: "/es/:path*", destination: "/", permanent: true },
    ];

    return [...postRedirects, ...deletedLocaleRedirects];
  },
};

module.exports = nextConfig;
