/**
 * /api/posts - 포스트 관리 API
 *
 * GET    /api/posts           → 전체 목록
 * GET    /api/posts?slug=xxx  → 개별 조회
 * POST   /api/posts           → 새 글 생성
 * PUT    /api/posts           → 글 수정
 * DELETE /api/posts?slug=xxx  → 글 삭제
 */
import { NextRequest, NextResponse } from "next/server";
import fs from "fs";
import path from "path";
import matter from "gray-matter";

const POSTS_DIR = path.join(process.cwd(), "content/posts");
const AUTH_TOKEN = process.env.ADMIN_TOKEN || "sero-admin-2026"; // .env에서 설정

function checkAuth(req: NextRequest): boolean {
  const token = req.headers.get("authorization")?.replace("Bearer ", "");
  return token === AUTH_TOKEN;
}

// GET: 전체 목록 또는 개별 조회
export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const slug = searchParams.get("slug");

  if (slug) {
    const filePath = path.join(POSTS_DIR, `${slug}.mdx`);
    if (!fs.existsSync(filePath)) {
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }
    const raw = fs.readFileSync(filePath, "utf-8");
    const { data, content } = matter(raw);
    return NextResponse.json({ meta: { ...data, slug }, content });
  }

  // 전체 목록
  if (!fs.existsSync(POSTS_DIR)) {
    return NextResponse.json({ posts: [] });
  }

  const files = fs.readdirSync(POSTS_DIR).filter((f) => f.endsWith(".mdx"));
  const posts = files
    .map((file) => {
      const raw = fs.readFileSync(path.join(POSTS_DIR, file), "utf-8");
      const { data } = matter(raw);
      return {
        slug: file.replace(/\.mdx$/, ""),
        title: data.title || "",
        description: data.description || "",
        date: data.date || "",
        category: data.category || "",
        tags: data.tags || [],
        published: data.published !== false,
      };
    })
    .sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
    );

  return NextResponse.json({ posts });
}

// POST: 새 글 생성
export async function POST(req: NextRequest) {
  if (!checkAuth(req)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json();
  const { title, description, category, tags, content, slug, published, coupangLinks } = body;

  if (!title || !content) {
    return NextResponse.json({ error: "title and content required" }, { status: 400 });
  }

  const today = new Date().toISOString().split("T")[0];
  const finalSlug =
    slug ||
    `${today}-${title.replace(/[^\w가-힣\s]/g, "").replace(/\s+/g, "-").toLowerCase().slice(0, 50)}`;

  const frontmatter: Record<string, any> = {
    title,
    description: description || "",
    date: today,
    category: category || "review",
    tags: tags || [],
    thumbnail: "",
    published: published ?? false,
  };

  if (coupangLinks && coupangLinks.length > 0) {
    frontmatter.coupangLinks = coupangLinks;
  }

  const mdx = matter.stringify(content, frontmatter);

  if (!fs.existsSync(POSTS_DIR)) {
    fs.mkdirSync(POSTS_DIR, { recursive: true });
  }

  const filePath = path.join(POSTS_DIR, `${finalSlug}.mdx`);
  fs.writeFileSync(filePath, mdx, "utf-8");

  return NextResponse.json({
    success: true,
    slug: finalSlug,
    path: `/posts/${finalSlug}`,
  });
}

// PUT: 글 수정
export async function PUT(req: NextRequest) {
  if (!checkAuth(req)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const body = await req.json();
  const { slug, title, description, category, tags, content, published, coupangLinks } = body;

  if (!slug) {
    return NextResponse.json({ error: "slug required" }, { status: 400 });
  }

  const filePath = path.join(POSTS_DIR, `${slug}.mdx`);
  if (!fs.existsSync(filePath)) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  const existing = fs.readFileSync(filePath, "utf-8");
  const { data: oldData, content: oldContent } = matter(existing);

  const newData = {
    ...oldData,
    ...(title !== undefined && { title }),
    ...(description !== undefined && { description }),
    ...(category !== undefined && { category }),
    ...(tags !== undefined && { tags }),
    ...(published !== undefined && { published }),
    ...(coupangLinks !== undefined && { coupangLinks }),
  };

  const newContent = content !== undefined ? content : oldContent;
  const mdx = matter.stringify(newContent, newData);
  fs.writeFileSync(filePath, mdx, "utf-8");

  return NextResponse.json({ success: true, slug });
}

// DELETE: 글 삭제
export async function DELETE(req: NextRequest) {
  if (!checkAuth(req)) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const { searchParams } = new URL(req.url);
  const slug = searchParams.get("slug");

  if (!slug) {
    return NextResponse.json({ error: "slug required" }, { status: 400 });
  }

  const filePath = path.join(POSTS_DIR, `${slug}.mdx`);
  if (!fs.existsSync(filePath)) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  fs.unlinkSync(filePath);
  return NextResponse.json({ success: true, deleted: slug });
}
