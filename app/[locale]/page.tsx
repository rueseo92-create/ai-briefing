import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";
import { PostCard } from "@/components/PostCard";
import { CoupangLinkAd, CoupangSidebarAd } from "@/components/CoupangAd";
import { getDictionary, localizedHref, defaultLocale, type Locale } from "@/lib/i18n";

export default async function Home({ params }: { params: { locale: string } }) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);
  const lh = (path: string) => localizedHref(path, locale);

  const posts = getAllPosts();
  const featured = posts[0];
  const recent = posts.slice(1, 7);

  const diffLabel = (d: string) =>
    d === "beginner" ? dict.post.beginner : d === "intermediate" ? dict.post.intermediate : dict.post.advanced;

  return (
    <div className="pt-32 pb-20 max-w-7xl mx-auto px-6 lg:px-12">
      {/* Hero */}
      {featured ? (
        <section className="mb-16">
          <a
            href={lh(`/posts/${featured.slug}`)}
            className="group relative block overflow-hidden rounded-2xl bg-gradient-to-br from-indigo-50 via-white to-cyan-50 p-12 lg:p-20 shadow-sm border border-indigo-100/50 hover:shadow-lg transition-all"
          >
            <div className="max-w-2xl relative z-10">
              <span className="inline-flex items-center px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold mb-6 tracking-wider uppercase">
                {dict.home.latest}
              </span>
              <h1 className="text-4xl lg:text-6xl font-extrabold text-on-surface mb-6 leading-[1.1] tracking-tight font-headline">
                {featured.title}
              </h1>
              <p className="text-lg text-on-surface-variant mb-8 leading-relaxed max-w-xl">
                {featured.description}
              </p>
              <div className="flex items-center gap-4 text-sm text-slate-500 font-medium">
                <span>{featured.date}</span>
                <span className="w-1 h-1 bg-slate-300 rounded-full" />
                <span className="text-primary">{featured.category}</span>
                {featured.difficulty && (
                  <>
                    <span className="w-1 h-1 bg-slate-300 rounded-full" />
                    <span className="px-2 py-0.5 rounded bg-slate-100 text-xs">{diffLabel(featured.difficulty)}</span>
                  </>
                )}
              </div>
            </div>
            <div className="absolute top-0 right-0 w-1/2 h-full bg-gradient-to-l from-primary/5 to-transparent pointer-events-none" />
          </a>
        </section>
      ) : (
        <section className="mb-16">
          <div className="rounded-2xl bg-gradient-to-br from-indigo-50 via-white to-cyan-50 p-12 lg:p-20 shadow-sm border border-indigo-100/50">
            <div className="max-w-2xl">
              <div className="flex items-center gap-3 mb-6">
                <span className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-primary text-white text-xl font-bold">AI</span>
                <h1 className="text-4xl lg:text-6xl font-extrabold text-on-surface leading-[1.1] tracking-tight font-headline">브리핑</h1>
              </div>
              <p className="text-lg text-on-surface-variant leading-relaxed">{dict.meta.siteDescription}</p>
              <p className="mt-4 text-sm text-slate-400">{dict.home.firstPostSoon}</p>
            </div>
          </div>
        </section>
      )}

      {siteConfig.coupang.enabled && (
        <div className="mb-8">
          <CoupangLinkAd
            keywords={["삼성 갤럭시북4 프로 노트북", "로지텍 MX Keys S 키보드", "LG 울트라와이드 모니터", "에어팟 프로 2세대"]}
            title={dict.home.coupangTitle}
          />
        </div>
      )}

      {/* Category Filter */}
      <section className="mb-12">
        <div className="flex items-center gap-3 overflow-x-auto pb-4 no-scrollbar">
          <a href={lh("/")} className="px-6 py-2.5 rounded-full bg-primary text-on-primary font-bold text-sm shadow-md shadow-primary/20 whitespace-nowrap">
            {dict.home.all}
          </a>
          {siteConfig.categories.map((cat) => (
            <a key={cat.slug} href={lh(`/categories/${cat.slug}`)} className="px-6 py-2.5 rounded-full bg-surface-container-low text-on-surface-variant hover:bg-primary/10 hover:text-primary transition-colors font-medium text-sm whitespace-nowrap">
              {cat.emoji} {cat.name}
            </a>
          ))}
        </div>
      </section>

      {/* Main */}
      <div className="flex flex-col lg:flex-row gap-12">
        <div className="flex-1">
          {recent.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              {recent.map((post) => (
                <PostCard key={post.slug} post={post} locale={locale} />
              ))}
            </div>
          ) : posts.length === 0 ? (
            <div className="py-20 text-center">
              <p className="text-6xl mb-4">🤖</p>
              <h2 className="text-xl font-bold text-on-surface mb-2 font-headline">{dict.home.noPosts}</h2>
              <p className="text-on-surface-variant text-sm">{dict.home.noPostsDesc}</p>
            </div>
          ) : null}

          {posts.length > 6 && (
            <div className="mt-16 text-center">
              <a href={lh("/posts")} className="inline-flex items-center gap-2 px-8 py-3 bg-slate-100 text-on-surface font-bold rounded-lg hover:bg-slate-200 transition-colors">
                {dict.home.viewAllPosts}
                <span className="material-symbols-outlined text-sm">arrow_forward</span>
              </a>
            </div>
          )}
        </div>

        {/* Sidebar */}
        <aside className="w-full lg:w-[320px] space-y-12">
          <section>
            <h4 className="text-sm font-bold text-on-surface mb-6 flex items-center gap-2">
              <span className="material-symbols-outlined text-lg text-primary">tag</span>
              {dict.home.popularKeywords}
            </h4>
            <div className="flex flex-wrap gap-2">
              {posts
                .flatMap((p) => p.tags)
                .filter((v, i, a) => a.indexOf(v) === i)
                .slice(0, 10)
                .map((tag) => (
                  <a key={tag} href={lh(`/search?tag=${encodeURIComponent(tag)}`)} className="px-3 py-1.5 bg-white border border-slate-200 rounded-md text-xs text-on-surface-variant hover:border-primary hover:text-primary transition-all">
                    #{tag}
                  </a>
                ))}
            </div>
          </section>

          {siteConfig.coupang.enabled && (
            <CoupangSidebarAd keywords={["챗GPT 활용법 도서", "삼성 갤럭시북4 프로 노트북", "로지텍 MX Master 3S", "LG 울트라와이드 모니터 34인치", "에어팟 프로 2세대"]} />
          )}

          <section className="bg-gradient-to-b from-indigo-50 to-white rounded-2xl p-8 border border-indigo-100/50">
            <h4 className="text-lg font-bold text-on-surface mb-2 font-headline">{dict.home.newsletter}</h4>
            <p className="text-sm text-on-surface-variant mb-6 leading-relaxed">{dict.home.newsletterDesc}</p>
            <form className="space-y-3" action="#">
              <input className="w-full px-4 py-3 rounded-lg border border-slate-200 bg-white text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary shadow-sm" placeholder={dict.home.emailPlaceholder} type="email" />
              <button className="w-full py-3 bg-primary text-on-primary font-bold rounded-lg hover:bg-primary-container transition-colors shadow-lg shadow-primary/20">{dict.home.subscribe}</button>
            </form>
            <p className="mt-4 text-[10px] text-slate-400 text-center">{dict.home.noSpam}</p>
          </section>

          <section className="bg-slate-50 rounded-xl p-6 border border-slate-100">
            <h4 className="text-sm font-bold text-on-surface mb-4 flex items-center gap-2">
              <span className="material-symbols-outlined text-lg text-secondary">info</span>
              {dict.home.aboutThisBlog}
            </h4>
            <ul className="space-y-2 text-xs text-on-surface-variant leading-relaxed">
              {dict.home.aboutItems.map((item, i) => (
                <li key={i} className="flex items-start gap-2">
                  <span className="text-primary mt-0.5">&#10003;</span>
                  {item}
                </li>
              ))}
            </ul>
          </section>
        </aside>
      </div>
    </div>
  );
}
