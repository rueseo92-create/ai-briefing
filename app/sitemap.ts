/**
 * sitemap.xml 동적 생성
 * - 다국어(ko/en/zh/ja/es) 모든 페이지 포함
 * - 모든 포스트 자동 포함
 * - 카테고리 페이지 포함
 * - alternates (hreflang) 포함
 * - lastmod 날짜 자동 반영
 */
import { MetadataRoute } from "next";
import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";

const LOCALES = ["ko", "en"] as const;
const BASE = siteConfig.url;

function localUrl(path: string, locale: string): string {
  if (locale === "ko") return `${BASE}${path}`;
  return `${BASE}/${locale}${path}`;
}

function alternates(path: string) {
  const languages: Record<string, string> = {};
  for (const l of LOCALES) {
    languages[l] = localUrl(path, l);
  }
  languages["x-default"] = localUrl(path, "ko");
  return { languages };
}

export default function sitemap(): MetadataRoute.Sitemap {
  const posts = getAllPosts();
  const entries: MetadataRoute.Sitemap = [];

  // 정적 페이지 (모든 로케일)
  const staticPaths = [
    { path: "", freq: "daily" as const, priority: 1.0 },
    { path: "/posts", freq: "daily" as const, priority: 0.9 },
    { path: "/search", freq: "weekly" as const, priority: 0.6 },
    { path: "/about", freq: "monthly" as const, priority: 0.5 },
    { path: "/business", freq: "monthly" as const, priority: 0.6 },
    { path: "/privacy", freq: "yearly" as const, priority: 0.3 },
  ];

  for (const page of staticPaths) {
    for (const locale of LOCALES) {
      entries.push({
        url: localUrl(page.path, locale),
        lastModified: new Date(),
        changeFrequency: page.freq,
        priority: page.priority,
        alternates: alternates(page.path),
      });
    }
  }

  // 카테고리 페이지 (모든 로케일)
  for (const cat of siteConfig.categories) {
    const catPath = `/categories/${cat.slug}`;
    for (const locale of LOCALES) {
      entries.push({
        url: localUrl(catPath, locale),
        lastModified: new Date(),
        changeFrequency: "weekly",
        priority: 0.8,
        alternates: alternates(catPath),
      });
    }
  }

  // 포스트 페이지 (모든 로케일)
  for (const post of posts) {
    const postPath = `/posts/${post.slug}`;
    for (const locale of LOCALES) {
      entries.push({
        url: localUrl(postPath, locale),
        lastModified: new Date(post.date),
        changeFrequency: "monthly",
        priority: locale === "ko" ? 0.8 : 0.6,
        alternates: alternates(postPath),
      });
    }
  }

  return entries;
}
