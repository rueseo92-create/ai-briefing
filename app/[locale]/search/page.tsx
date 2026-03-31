import { getAllPosts } from "@/lib/posts";
import { PostCard } from "@/components/PostCard";
import { getDictionary, localizedHref, defaultLocale, type Locale } from "@/lib/i18n";

export default async function SearchPage({
  params,
  searchParams,
}: {
  params: { locale: string };
  searchParams: { q?: string; tag?: string };
}) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);
  const lh = (path: string) => localizedHref(path, locale);

  const query = searchParams.q?.trim() || "";
  const tag = searchParams.tag?.trim() || "";
  const allPosts = getAllPosts(locale as "ko" | "en");

  const tagCounts: Record<string, number> = {};
  allPosts.forEach((p) => p.tags.forEach((t) => { tagCounts[t] = (tagCounts[t] || 0) + 1; }));
  const popularTags = Object.entries(tagCounts).sort((a, b) => b[1] - a[1]).slice(0, 20).map(([t]) => t);

  const hasSearch = query.length > 0 || tag.length > 0;
  const results = hasSearch
    ? allPosts.filter((post) => {
        const q = query.toLowerCase();
        const matchesQuery = !query || post.title.toLowerCase().includes(q) || post.description.toLowerCase().includes(q) || post.tags.some((t) => t.toLowerCase().includes(q));
        const matchesTag = !tag || post.tags.some((t) => t.toLowerCase() === tag.toLowerCase());
        return matchesQuery && matchesTag;
      })
    : [];

  return (
    <div className="pt-28 pb-20 max-w-7xl mx-auto px-6 lg:px-12">
      <header className="mb-10">
        <h1 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline mb-2">{dict.search.title}</h1>
        <p className="text-on-surface-variant text-sm">{dict.search.description}</p>
      </header>

      <form action={lh("/search")} method="GET" className="mb-8">
        <div className="flex gap-3">
          <div className="flex-1 relative">
            <span className="material-symbols-outlined absolute left-4 top-1/2 -translate-y-1/2 text-slate-400 text-xl">search</span>
            <input name="q" type="text" defaultValue={query} placeholder={dict.search.placeholder} className="w-full pl-12 pr-4 py-3.5 rounded-xl border border-slate-200 bg-white text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary shadow-sm" />
          </div>
          <button type="submit" className="px-6 py-3.5 bg-primary text-on-primary font-bold rounded-xl hover:bg-primary-container transition-colors shadow-lg shadow-primary/20 text-sm">{dict.search.button}</button>
        </div>
      </form>

      <section className="mb-10">
        <h4 className="text-sm font-bold text-on-surface mb-4 flex items-center gap-2">
          <span className="material-symbols-outlined text-lg text-primary">tag</span>
          {dict.search.popularKeywords}
        </h4>
        <div className="flex flex-wrap gap-2">
          {popularTags.map((t) => (
            <a key={t} href={lh(`/search?tag=${encodeURIComponent(t)}`)} className={`px-3 py-1.5 rounded-md text-xs transition-all ${tag === t ? "bg-primary text-on-primary font-bold shadow-md shadow-primary/20" : "bg-white border border-slate-200 text-on-surface-variant hover:border-primary hover:text-primary"}`}>
              #{t}
              <span className="ml-1 text-[10px] opacity-60">({tagCounts[t]})</span>
            </a>
          ))}
        </div>
      </section>

      {hasSearch && (
        <>
          <div className="flex items-center gap-3 mb-6">
            <p className="text-sm text-on-surface-variant">
              {query && <span>&ldquo;<strong className="text-on-surface">{query}</strong>&rdquo;</span>}
              {query && tag && <span> + </span>}
              {tag && <span>{dict.search.tag}: <strong className="text-primary">#{tag}</strong></span>}
              <span className="ml-1">{dict.search.results.replace("{n}", String(results.length))}</span>
            </p>
            {(query || tag) && <a href={lh("/search")} className="text-xs text-slate-400 hover:text-primary transition-colors">{dict.search.reset}</a>}
          </div>
          {results.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
              {results.map((post) => <PostCard key={post.slug} post={post} locale={locale} />)}
            </div>
          ) : (
            <div className="py-16 text-center">
              <span className="material-symbols-outlined text-5xl text-slate-300 mb-4 block">search_off</span>
              <h2 className="text-lg font-bold text-on-surface mb-2 font-headline">{dict.search.noResults}</h2>
              <p className="text-on-surface-variant text-sm">{dict.search.noResultsDesc}</p>
            </div>
          )}
        </>
      )}

      {!hasSearch && (
        <div className="py-16 text-center">
          <span className="material-symbols-outlined text-5xl text-slate-300 mb-4 block">manage_search</span>
          <h2 className="text-lg font-bold text-on-surface mb-2 font-headline">{dict.search.initialTitle}</h2>
          <p className="text-on-surface-variant text-sm">{dict.search.initialDesc.replace("{n}", String(allPosts.length))}</p>
        </div>
      )}
    </div>
  );
}
