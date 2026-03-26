/**
 * lib/seo.ts - SEO 유틸리티
 *
 * - 구조화 데이터 (JSON-LD)
 * - 키워드 밀도 분석
 * - 읽기 시간 계산
 * - SEO 감사
 */

import { siteConfig } from "./config";
import type { PostMeta } from "./posts";

// ─── JSON-LD 구조화 데이터 ──────────────────

export function websiteSchema() {
  return {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: siteConfig.name,
    url: siteConfig.url,
    description: siteConfig.description,
    inLanguage: "ko-KR",
    potentialAction: {
      "@type": "SearchAction",
      target: {
        "@type": "EntryPoint",
        urlTemplate: `${siteConfig.url}/search?q={search_term_string}`,
      },
      "query-input": "required name=search_term_string",
    },
    publisher: organizationSchema(),
  };
}

export function organizationSchema() {
  return {
    "@type": "Organization",
    name: siteConfig.name,
    url: siteConfig.url,
    logo: `${siteConfig.url}/logo.png`,
  };
}

export function articleSchema(post: PostMeta) {
  return {
    "@context": "https://schema.org",
    "@type": "Article",
    headline: post.title,
    description: post.description,
    datePublished: post.date,
    dateModified: post.date,
    author: {
      "@type": "Person",
      name: siteConfig.author,
      url: siteConfig.url,
    },
    publisher: organizationSchema(),
    mainEntityOfPage: {
      "@type": "WebPage",
      "@id": `${siteConfig.url}/posts/${post.slug}`,
    },
    image: post.thumbnail || `${siteConfig.url}/og-default.png`,
    inLanguage: "ko-KR",
    keywords: post.tags.join(", "),
  };
}

export function breadcrumbSchema(
  items: { name: string; url: string }[]
) {
  return {
    "@context": "https://schema.org",
    "@type": "BreadcrumbList",
    itemListElement: items.map((item, i) => ({
      "@type": "ListItem",
      position: i + 1,
      name: item.name,
      item: item.url,
    })),
  };
}

export function faqSchema(faqs: { question: string; answer: string }[]) {
  return {
    "@context": "https://schema.org",
    "@type": "FAQPage",
    mainEntity: faqs.map((faq) => ({
      "@type": "Question",
      name: faq.question,
      acceptedAnswer: {
        "@type": "Answer",
        text: faq.answer,
      },
    })),
  };
}

// ─── SEO 분석 유틸리티 ──────────────────

export function analyzeKeywordDensity(
  content: string,
  keyword: string
): {
  density: number;
  count: number;
  totalWords: number;
  status: "low" | "optimal" | "high";
} {
  const words = content.replace(/[#*\-_\[\]()]/g, "").split(/\s+/).length;
  const regex = new RegExp(keyword, "gi");
  const matches = content.match(regex);
  const count = matches ? matches.length : 0;
  const density = (count / words) * 100;

  let status: "low" | "optimal" | "high" = "optimal";
  if (density < 1) status = "low";
  if (density > 3.5) status = "high";

  return { density, count, totalWords: words, status };
}

export function calculateReadingTime(content: string): number {
  const charCount = content.replace(/\s/g, "").length;
  return Math.max(1, Math.ceil(charCount / 500));
}

export function countCharacters(content: string): {
  total: number;
  withoutSpaces: number;
} {
  return {
    total: content.length,
    withoutSpaces: content.replace(/\s/g, "").length,
  };
}

export function seoAudit(
  post: PostMeta,
  content: string
): {
  score: number;
  checks: { label: string; passed: boolean; tip?: string }[];
} {
  const checks = [
    {
      label: "제목 60자 이하",
      passed: post.title.length <= 60,
      tip: post.title.length > 60 ? `현재 ${post.title.length}자 → 60자 이하로` : undefined,
    },
    {
      label: "meta description 155자 이하",
      passed: post.description.length > 0 && post.description.length <= 155,
      tip: post.description.length > 155
        ? `현재 ${post.description.length}자`
        : post.description.length === 0
        ? "description이 비어있음"
        : undefined,
    },
    {
      label: "H2 소제목 3개 이상",
      passed: (content.match(/^## /gm) || []).length >= 3,
      tip: `현재 ${(content.match(/^## /gm) || []).length}개`,
    },
    {
      label: "H3 소제목 존재",
      passed: (content.match(/^### /gm) || []).length >= 1,
    },
    {
      label: "본문 1000자 이상",
      passed: content.replace(/\s/g, "").length >= 1000,
      tip: `현재 ${content.replace(/\s/g, "").length}자`,
    },
    {
      label: "이미지 alt 태그 존재",
      passed:
        !content.includes("![") || content.includes("![") && !content.includes("![]"),
    },
    {
      label: "내부 링크 포함",
      passed: content.includes("](/posts/") || content.includes("](/categories/"),
    },
    {
      label: "CTA/참조 문구 존재",
      passed:
        content.includes("확인") ||
        content.includes("참고") ||
        content.includes("출처") ||
        content.includes("링크") ||
        content.includes("신청"),
    },
    {
      label: "태그 3개 이상",
      passed: post.tags.length >= 3,
    },
    {
      label: "출처 링크 포함",
      passed: (post.sources || []).length > 0,
    },
  ];

  const passed = checks.filter((c) => c.passed).length;
  const score = Math.round((passed / checks.length) * 100);

  return { score, checks };
}

export function ogImageUrl(title: string, category?: string): string {
  const params = new URLSearchParams({ title });
  if (category) params.set("category", category);
  return `${siteConfig.url}/api/og?${params.toString()}`;
}

export function canonicalUrl(path: string): string {
  const clean = path.startsWith("/") ? path : `/${path}`;
  return `${siteConfig.url}${clean}`;
}
