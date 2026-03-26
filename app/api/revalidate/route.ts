/**
 * /api/revalidate - 온디맨드 ISR 재검증
 *
 * sero-blog.py에서 새 글 생성 후 호출하면
 * Vercel이 해당 페이지를 즉시 재빌드
 *
 * POST /api/revalidate
 * Body: { "slug": "post-slug", "token": "..." }
 */
import { NextRequest, NextResponse } from "next/server";
import { revalidatePath } from "next/cache";

export async function POST(req: NextRequest) {
  const body = await req.json();
  const token = body.token || req.headers.get("authorization")?.replace("Bearer ", "");

  if (token !== (process.env.REVALIDATION_TOKEN || "sero-revalidate-2026")) {
    return NextResponse.json({ error: "Invalid token" }, { status: 401 });
  }

  const slug = body.slug;

  // 특정 포스트 재검증
  if (slug) {
    revalidatePath(`/posts/${slug}`);
    revalidatePath("/"); // 홈도 갱신 (최신 글 표시)
    revalidatePath("/posts"); // 전체 목록도 갱신
    return NextResponse.json({ revalidated: true, slug });
  }

  // slug 없으면 전체 사이트 재검증
  revalidatePath("/", "layout");
  return NextResponse.json({ revalidated: true, scope: "all" });
}
