import fs from "fs";
import path from "path";
import matter from "gray-matter";

const POSTS_DIR = path.join(process.cwd(), "content/posts");

export interface PostMeta {
  slug: string;
  title: string;
  description: string;
  date: string;
  category: string;
  tags: string[];
  thumbnail?: string;
  sources?: SourceLink[];
  difficulty?: "beginner" | "intermediate" | "advanced";
  tldr?: string;
  published: boolean;
}

export interface SourceLink {
  name: string;
  url: string;
  type?: string; // "government" | "paper" | "news" | "official"
}

export interface Post {
  meta: PostMeta;
  content: string;
}

// 전체 포스트 목록 (정렬: 최신순)
export function getAllPosts(): PostMeta[] {
  if (!fs.existsSync(POSTS_DIR)) return [];

  const files = fs.readdirSync(POSTS_DIR).filter((f) => f.endsWith(".mdx"));

  const posts = files
    .map((file) => {
      const slug = file.replace(/\.mdx$/, "");
      const raw = fs.readFileSync(path.join(POSTS_DIR, file), "utf-8");
      const { data } = matter(raw);

      return {
        slug,
        title: data.title || "",
        description: data.description || "",
        date: data.date || "",
        category: data.category || "ai-news",
        tags: data.tags || [],
        thumbnail: data.thumbnail || null,
        sources: data.sources || [],
        difficulty: data.difficulty || null,
        tldr: data.tldr || null,
        published: data.published !== false,
      } as PostMeta;
    })
    .filter((p) => p.published)
    .sort((a, b) => {
      const dateDiff = new Date(b.date).getTime() - new Date(a.date).getTime();
      if (dateDiff !== 0) return dateDiff;
      // 같은 날짜면 slug 역순 (최신 파일이 위로)
      return b.slug.localeCompare(a.slug);
    });

  return posts;
}

// 개별 포스트
export function getPost(slug: string): Post | null {
  const filePath = path.join(POSTS_DIR, `${slug}.mdx`);
  if (!fs.existsSync(filePath)) return null;

  const raw = fs.readFileSync(filePath, "utf-8");
  const { data, content } = matter(raw);

  return {
    meta: {
      slug,
      title: data.title || "",
      description: data.description || "",
      date: data.date || "",
      category: data.category || "ai-news",
      tags: data.tags || [],
      thumbnail: data.thumbnail || null,
      sources: data.sources || [],
      difficulty: data.difficulty || null,
      tldr: data.tldr || null,
      published: data.published !== false,
    },
    content,
  };
}

// 카테고리별 포스트
export function getPostsByCategory(category: string): PostMeta[] {
  return getAllPosts().filter((p) => p.category === category);
}

// 관련 포스트 (같은 카테고리 + 태그 겹치는 것)
export function getRelatedPosts(slug: string, limit = 3): PostMeta[] {
  const current = getPost(slug);
  if (!current) return [];

  const all = getAllPosts().filter((p) => p.slug !== slug);

  return all
    .map((p) => {
      let score = 0;
      if (p.category === current.meta.category) score += 2;
      score += p.tags.filter((t) => current.meta.tags.includes(t)).length;
      return { ...p, score };
    })
    .sort((a, b) => b.score - a.score)
    .slice(0, limit);
}

// 전체 슬러그 목록 (정적 생성용)
export function getAllSlugs(): string[] {
  if (!fs.existsSync(POSTS_DIR)) return [];
  return fs
    .readdirSync(POSTS_DIR)
    .filter((f) => f.endsWith(".mdx"))
    .map((f) => f.replace(/\.mdx$/, ""));
}
