/**
 * sitemap.xml 동적 생성
 * - 한국어(ko) 페이지만 포함 (영문 콘텐츠 없으므로 제외)
 * - 모든 포스트 자동 포함
 * - 카테고리 페이지 포함
 * - lastmod 날짜 자동 반영
 */
import { MetadataRoute } from "next";
import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";

const BASE = siteConfig.url;

export default function sitemap(): MetadataRoute.Sitemap {
  const entries: MetadataRoute.Sitemap = [];

  // 정적 페이지 (한국어만)
  const staticPaths = [
    { path: "", freq: "daily" as const, priority: 1.0 },
    { path: "/posts", freq: "daily" as const, priority: 0.9 },
    { path: "/search", freq: "weekly" as const, priority: 0.6 },
    { path: "/about", freq: "monthly" as const, priority: 0.5 },
    { path: "/business", freq: "monthly" as const, priority: 0.6 },
    { path: "/privacy", freq: "yearly" as const, priority: 0.3 },
  ];

  for (const page of staticPaths) {
    entries.push({
      url: `${BASE}${page.path}`,
      lastModified: new Date(),
      changeFrequency: page.freq,
      priority: page.priority,
    });
  }

  // 카테고리 페이지
  for (const cat of siteConfig.categories) {
    entries.push({
      url: `${BASE}/categories/${cat.slug}`,
      lastModified: new Date(),
      changeFrequency: "weekly",
      priority: 0.8,
    });
  }

  // 포스트 페이지
  const posts = getAllPosts("ko");
  for (const post of posts) {
    entries.push({
      url: `${BASE}/posts/${post.slug}`,
      lastModified: new Date(post.date),
      changeFrequency: "monthly",
      priority: 0.8,
    });
  }

  return entries;
}
