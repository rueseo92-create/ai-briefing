import { Metadata } from "next";
import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";
import { PostCard } from "@/components/PostCard";

export const metadata: Metadata = {
  title: "검색",
  description: `${siteConfig.name}에서 글 검색하기`,
};

export default function SearchPage({
  searchParams,
}: {
  searchParams: { q?: string; tag?: string };
}) {
  const query = searchParams.q?.trim() || "";
  const tag = searchParams.tag?.trim() || "";
  const allPosts = getAllPosts();

  // 모든 태그 (인기순)
  const tagCounts: Record<string, number> = {};
  allPosts.forEach((p) =>
    p.tags.forEach((t) => {
      tagCounts[t] = (tagCounts[t] || 0) + 1;
    })
  );
  const popularTags = Object.entries(tagCounts)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 20)
    .map(([t]) => t);

  // 검색 필터링
  const hasSearch = query.length > 0 || tag.length > 0;
  const results = hasSearch
    ? allPosts.filter((post) => {
        const q = query.toLowerCase();
        const matchesQuery =
          !query ||
          post.title.toLowerCase().includes(q) ||
          post.description.toLowerCase().includes(q) ||
          post.tags.some((t) => t.toLowerCase().includes(q));
        const matchesTag =
          !tag || post.tags.some((t) => t.toLowerCase() === tag.toLowerCase());
        return matchesQuery && matchesTag;
      })
    : [];

  return (
    <div className="pt-28 pb-20 max-w-7xl mx-auto px-6 lg:px-12">
      {/* Header */}
      <header className="mb-10">
        <h1 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-2">
          검색
        </h1>
        <p className="text-on-surface-variant text-sm">
          키워드 또는 태그로 글을 찾아보세요
        </p>
      </header>

      {/* Search Form */}
      <form action="/search" method="GET" className="mb-8">
        <div className="flex gap-3">
          <div className="flex-1 relative">
            <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-xl">
              search
            </span>
            <input
              name="q"
              type="text"
              defaultValue={query}
              placeholder="검색어를 입력하세요 (예: ChatGPT, AI 자동화, 정부사업)"
              className="w-full pl-12 pr-4 py-3.5 rounded-xl border border-slate-200 bg-white text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary shadow-sm"
            />
          </div>
          <button
            type="submit"
            className="px-6 py-3.5 bg-primary text-on-primary font-bold rounded-xl hover:bg-primary-container transition-colors shadow-lg shadow-primary/20 text-sm"
          >
            검색
          </button>
        </div>
      </form>

      {/* Popular Tags */}
      <section className="mb-10">
        <h4 className="text-sm font-bold text-on-surface mb-4 flex items-center gap-2">
          <span className="material-symbols-outlined text-lg text-primary">tag</span>
          인기 키워드
        </h4>
        <div className="flex flex-wrap gap-2">
          {popularTags.map((t) => (
            <a
              key={t}
              href={`/search?tag=${encodeURIComponent(t)}`}
              className={`px-3 py-1.5 rounded-md text-xs transition-all ${
                tag === t
                  ? "bg-primary text-on-primary font-bold shadow-md shadow-primary/20"
                  : "bg-white border border-slate-200 text-on-surface-variant hover:border-primary hover:text-primary"
              }`}
            >
              #{t}
              <span className="ml-1 text-[10px] opacity-60">({tagCounts[t]})</span>
            </a>
          ))}
        </div>
      </section>

      {/* Results */}
      {hasSearch && (
        <>
          <div className="flex items-center gap-3 mb-6">
            <p className="text-sm text-on-surface-variant">
              {query && (
                <span>
                  &ldquo;<strong className="text-on-surface">{query}</strong>&rdquo;
                </span>
              )}
              {query && tag && <span> + </span>}
              {tag && (
                <span>
                  태그: <strong className="text-primary">#{tag}</strong>
                </span>
              )}
              <span className="ml-1">검색 결과 {results.length}건</span>
            </p>
            {(query || tag) && (
              <a
                href="/search"
                className="text-xs text-slate-400 hover:text-primary transition-colors"
              >
                초기화
              </a>
            )}
          </div>

          {results.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {results.map((post) => (
                <PostCard key={post.slug} post={post} />
              ))}
            </div>
          ) : (
            <div className="py-16 text-center">
              <span className="material-symbols-outlined text-5xl text-slate-300 mb-4 block">
                search_off
              </span>
              <h2 className="text-lg font-bold text-on-surface mb-2 font-headline">
                검색 결과가 없습니다
              </h2>
              <p className="text-on-surface-variant text-sm">
                다른 키워드로 검색하거나 인기 키워드를 눌러보세요
              </p>
            </div>
          )}
        </>
      )}

      {/* No search yet */}
      {!hasSearch && (
        <div className="py-16 text-center">
          <span className="material-symbols-outlined text-5xl text-slate-300 mb-4 block">
            manage_search
          </span>
          <h2 className="text-lg font-bold text-on-surface mb-2 font-headline">
            검색어를 입력하거나 키워드를 선택하세요
          </h2>
          <p className="text-on-surface-variant text-sm">
            총 {allPosts.length}개의 글에서 검색할 수 있습니다
          </p>
        </div>
      )}
    </div>
  );
}
