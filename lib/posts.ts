import fs from "fs";
import path from "path";
import matter from "gray-matter";

const POSTS_DIR = path.join(process.cwd(), "content/posts");

// ── 카테고리별 큐레이트된 Unsplash 썸네일 ──
const CATEGORY_IMAGES: Record<string, string[]> = {
  "ai-news": [
    "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=800&q=80",
    "https://images.unsplash.com/photo-1620712943543-bcc4688e7485?w=800&q=80",
    "https://images.unsplash.com/photo-1635070041078-e363dbe005cb?w=800&q=80",
    "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?w=800&q=80",
    "https://images.unsplash.com/photo-1535378620166-273708d44e4c?w=800&q=80",
    "https://images.unsplash.com/photo-1526374965328-7f61d4dc18c5?w=800&q=80",
  ],
  "gov-projects": [
    "https://images.unsplash.com/photo-1486406146926-c627a92ad1ab?w=800&q=80",
    "https://images.unsplash.com/photo-1523292562811-8fa7962a78c8?w=800&q=80",
    "https://images.unsplash.com/photo-1541872703-74c5e44368f9?w=800&q=80",
    "https://images.unsplash.com/photo-1577415124269-fc1140a69e91?w=800&q=80",
    "https://images.unsplash.com/photo-1517245386807-bb43f82c33c4?w=800&q=80",
    "https://images.unsplash.com/photo-1497366216548-37526070297c?w=800&q=80",
  ],
  "ai-tools": [
    "https://images.unsplash.com/photo-1551288049-bebda4e38f71?w=800&q=80",
    "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=800&q=80",
    "https://images.unsplash.com/photo-1518770660439-4636190af475?w=800&q=80",
    "https://images.unsplash.com/photo-1558494949-ef010cbdcc31?w=800&q=80",
    "https://images.unsplash.com/photo-1504639725590-34d0984388bd?w=800&q=80",
    "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800&q=80",
  ],
  tutorials: [
    "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=800&q=80",
    "https://images.unsplash.com/photo-1587620962725-abab7fe55159?w=800&q=80",
    "https://images.unsplash.com/photo-1498050108023-c5249f4df085?w=800&q=80",
    "https://images.unsplash.com/photo-1461749280684-dccba630e2f6?w=800&q=80",
    "https://images.unsplash.com/photo-1555949963-aa79dcee981c?w=800&q=80",
    "https://images.unsplash.com/photo-1542831371-29b0f74f9713?w=800&q=80",
  ],
  marketing: [
    "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=800&q=80",
    "https://images.unsplash.com/photo-1533750516457-a7f992034fec?w=800&q=80",
    "https://images.unsplash.com/photo-1432888498266-38ffec3eaf0a?w=800&q=80",
    "https://images.unsplash.com/photo-1560472355-536de3962603?w=800&q=80",
    "https://images.unsplash.com/photo-1504868584819-f8e8b4b6d7e3?w=800&q=80",
    "https://images.unsplash.com/photo-1611162617213-7d7a39e9b1d7?w=800&q=80",
  ],
};

/** slug 해시 기반으로 카테고리별 이미지 결정 (동일 slug = 동일 이미지) */
function autoThumbnail(slug: string, category: string): string {
  const images = CATEGORY_IMAGES[category] || CATEGORY_IMAGES["ai-news"];
  let hash = 0;
  for (let i = 0; i < slug.length; i++) {
    hash = ((hash << 5) - hash + slug.charCodeAt(i)) | 0;
  }
  return images[Math.abs(hash) % images.length];
}

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

      const category = data.category || "ai-news";
      return {
        slug,
        title: data.title || "",
        description: data.description || "",
        date: data.date || "",
        category,
        tags: data.tags || [],
        thumbnail: data.thumbnail || autoThumbnail(slug, category),
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

  const category = data.category || "ai-news";
  return {
    meta: {
      slug,
      title: data.title || "",
      description: data.description || "",
      date: data.date || "",
      category,
      tags: data.tags || [],
      thumbnail: data.thumbnail || autoThumbnail(slug, category),
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
