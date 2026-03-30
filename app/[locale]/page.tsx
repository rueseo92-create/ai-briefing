import Image from "next/image";
import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";
import { PostCard } from "@/components/PostCard";
import { CoupangLinkAd, CoupangSidebarAd } from "@/components/CoupangAd";
import { getDictionary, localizedHref, defaultLocale, type Locale } from "@/lib/i18n";

const categoryImages: Record<string, string> = {
  "ai-news": "https://images.unsplash.com/photo-1677442136019-21780ecad995?w=400&q=80",
  "gov-projects": "https://images.unsplash.com/photo-1523292562811-8fa7962a78c8?w=400&q=80",
  "ai-tools": "https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=400&q=80",
  tutorials: "https://images.unsplash.com/photo-1516321318423-f06f85e504b3?w=400&q=80",
  marketing: "https://images.unsplash.com/photo-1460925895917-afdab827c52f?w=400&q=80",
};

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
    <div>
      {/* ── Hero ── */}
      {featured ? (
        <section className="relative min-h-[540px] lg:min-h-[620px] flex items-end">
          <Image
            src="https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1920&q=80"
            alt="AI technology background"
            fill
            className="object-cover"
            priority
          />
          <div className="absolute inset-0 bg-gradient-to-t from-slate-900 via-slate-900/60 to-slate-900/30" />

          <div className="relative w-full max-w-7xl mx-auto px-6 lg:px-12 pb-16 pt-32">
            <div className="grid lg:grid-cols-2 gap-10 items-end">
              {/* 사이트 소개 */}
              <div>
                <div className="flex items-center gap-3 mb-6">
                  <span className="inline-flex items-center justify-center w-10 h-10 rounded-xl bg-white text-primary text-sm font-extrabold shadow-lg">
                    AI
                  </span>
                  <span className="text-2xl font-extrabold text-white font-headline tracking-tight">브리핑</span>
                </div>
                <p className="text-white/70 text-lg leading-relaxed max-w-md mb-6">
                  {dict.meta.siteDescription}
                </p>
                <div className="flex items-center gap-6 text-sm">
                  <div className="flex items-center gap-2 text-white/50">
                    <span className="material-symbols-outlined text-base text-indigo-300">article</span>
                    <span><strong className="text-white">{posts.length}</strong>개 글</span>
                  </div>
                  <div className="flex items-center gap-2 text-white/50">
                    <span className="material-symbols-outlined text-base text-emerald-300">schedule</span>
                    <span>매일 업데이트</span>
                  </div>
                  <div className="flex items-center gap-2 text-white/50">
                    <span className="material-symbols-outlined text-base text-cyan-300">smart_toy</span>
                    <span>AI 자동 발행</span>
                  </div>
                </div>
              </div>

              {/* 최신글 카드 */}
              <a
                href={lh(`/posts/${featured.slug}`)}
                className="group block rounded-2xl bg-white/10 backdrop-blur-md border border-white/10 p-6 lg:p-8 hover:bg-white/15 transition-all"
              >
                <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-indigo-500/30 text-indigo-200 text-xs font-bold mb-4 tracking-wider uppercase">
                  <span className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-pulse" />
                  {dict.home.latest}
                </span>
                <h1 className="text-2xl lg:text-3xl font-extrabold text-white mb-3 leading-snug tracking-tight font-headline group-hover:text-indigo-200 transition-colors line-clamp-2">
                  {featured.title}
                </h1>
                <p className="text-sm text-white/60 leading-relaxed line-clamp-2 mb-4">
                  {featured.description}
                </p>
                <div className="flex items-center gap-3 text-xs text-white/40">
                  <span>{featured.date}</span>
                  <span className="w-1 h-1 bg-white/20 rounded-full" />
                  <span className="text-indigo-300">{featured.category}</span>
                  {featured.difficulty && (
                    <>
                      <span className="w-1 h-1 bg-white/20 rounded-full" />
                      <span className="px-2 py-0.5 rounded bg-white/10 text-white/50">{diffLabel(featured.difficulty)}</span>
                    </>
                  )}
                </div>
              </a>
            </div>
          </div>
        </section>
      ) : (
        <section className="relative min-h-[400px] flex items-center">
          <Image
            src="https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=1920&q=80"
            alt="AI technology background"
            fill
            className="object-cover"
            priority
          />
          <div className="absolute inset-0 bg-gradient-to-r from-slate-900/90 to-slate-900/60" />
          <div className="relative max-w-7xl mx-auto px-6 lg:px-12 py-32 w-full">
            <div className="flex items-center gap-3 mb-6">
              <span className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-white text-primary text-xl font-bold">AI</span>
              <h1 className="text-4xl lg:text-6xl font-extrabold text-white leading-[1.1] tracking-tight font-headline">브리핑</h1>
            </div>
            <p className="text-lg text-white/70 leading-relaxed max-w-xl">{dict.meta.siteDescription}</p>
            <p className="mt-4 text-sm text-white/40">{dict.home.firstPostSoon}</p>
          </div>
        </section>
      )}

      {/* ── Category Cards ── */}
      <section className="relative -mt-8 z-10 max-w-7xl mx-auto px-6 lg:px-12 mb-16">
        <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-3">
          {siteConfig.categories.map((cat) => (
            <a
              key={cat.slug}
              href={lh(`/categories/${cat.slug}`)}
              className="group relative rounded-xl overflow-hidden h-24 lg:h-28"
            >
              <Image
                src={categoryImages[cat.slug] || categoryImages["ai-news"]}
                alt={cat.name}
                fill
                className="object-cover group-hover:scale-110 transition-transform duration-500"
              />
              <div className="absolute inset-0 bg-slate-900/50 group-hover:bg-primary/60 transition-colors duration-300" />
              <div className="absolute inset-0 flex flex-col items-center justify-center text-center px-2">
                <span className="text-lg mb-1">{cat.emoji}</span>
                <span className="text-white text-xs font-bold tracking-wide">{cat.name}</span>
              </div>
            </a>
          ))}
        </div>
      </section>

      {siteConfig.coupang.enabled && (
        <div className="max-w-7xl mx-auto px-6 lg:px-12 mb-12">
          <CoupangLinkAd
            keywords={["삼성 갤럭시북4 프로 노트북", "로지텍 MX Keys S 키보드", "LG 울트라와이드 모니터", "에어팟 프로 2세대"]}
            title={dict.home.coupangTitle}
          />
        </div>
      )}

      {/* ── Main Content ── */}
      <div className="max-w-7xl mx-auto px-6 lg:px-12 pb-20">
        <div className="flex flex-col lg:flex-row gap-12">
          {/* Posts */}
          <div className="flex-1">
            {/* Section Header */}
            <div className="flex items-center justify-between mb-8">
              <div className="flex items-center gap-3">
                <div className="w-1 h-6 bg-primary rounded-full" />
                <h2 className="text-xl font-extrabold text-on-surface font-headline">{dict.home.latest}</h2>
              </div>
              <a href={lh("/posts")} className="text-sm text-primary font-semibold hover:underline flex items-center gap-1">
                {dict.home.viewAllPosts}
                <span className="material-symbols-outlined text-sm">arrow_forward</span>
              </a>
            </div>

            {recent.length > 0 ? (
              <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
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
              <div className="mt-12 text-center">
                <a href={lh("/posts")} className="inline-flex items-center gap-2 px-8 py-3.5 bg-slate-900 text-white font-bold rounded-xl hover:bg-slate-800 transition-colors text-sm shadow-lg">
                  {dict.home.viewAllPosts}
                  <span className="material-symbols-outlined text-sm">arrow_forward</span>
                </a>
              </div>
            )}
          </div>

          {/* Sidebar */}
          <aside className="w-full lg:w-[320px] space-y-8">
            {/* 태그 */}
            <section className="rounded-2xl bg-white border border-slate-200/80 p-6">
              <h4 className="text-sm font-bold text-on-surface mb-5 flex items-center gap-2">
                <span className="material-symbols-outlined text-lg text-primary">tag</span>
                {dict.home.popularKeywords}
              </h4>
              <div className="flex flex-wrap gap-2">
                {posts
                  .flatMap((p) => p.tags)
                  .filter((v, i, a) => a.indexOf(v) === i)
                  .slice(0, 12)
                  .map((tag) => (
                    <a key={tag} href={lh(`/search?tag=${encodeURIComponent(tag)}`)} className="px-3 py-1.5 bg-slate-50 border border-slate-200 rounded-lg text-xs text-on-surface-variant hover:border-primary hover:text-primary hover:bg-primary/5 transition-all">
                      #{tag}
                    </a>
                  ))}
              </div>
            </section>

            {siteConfig.coupang.enabled && (
              <CoupangSidebarAd keywords={["챗GPT 활용법 도서", "삼성 갤럭시북4 프로 노트북", "로지텍 MX Master 3S", "LG 울트라와이드 모니터 34인치", "에어팟 프로 2세대"]} />
            )}

            {/* 뉴스레터 */}
            <section className="relative rounded-2xl overflow-hidden">
              <Image
                src="https://images.unsplash.com/photo-1499750310107-5fef28a66643?w=640&q=80"
                alt="Newsletter"
                fill
                className="object-cover"
              />
              <div className="absolute inset-0 bg-gradient-to-t from-slate-900 via-slate-900/85 to-slate-900/60" />
              <div className="relative p-6">
                <h4 className="text-lg font-bold text-white mb-2 font-headline">{dict.home.newsletter}</h4>
                <p className="text-sm text-white/60 mb-5 leading-relaxed">{dict.home.newsletterDesc}</p>
                <form className="space-y-3" action="#">
                  <input className="w-full px-4 py-3 rounded-xl border border-white/10 bg-white/10 backdrop-blur-sm text-sm text-white placeholder-white/40 focus:ring-2 focus:ring-primary/40 focus:border-primary/40" placeholder={dict.home.emailPlaceholder} type="email" />
                  <button className="w-full py-3 bg-white text-slate-900 font-bold rounded-xl hover:bg-slate-100 transition-colors shadow-lg text-sm">{dict.home.subscribe}</button>
                </form>
                <p className="mt-4 text-[10px] text-white/30 text-center">{dict.home.noSpam}</p>
              </div>
            </section>

            {/* 소개 */}
            <section className="rounded-2xl bg-white border border-slate-200/80 p-6">
              <h4 className="text-sm font-bold text-on-surface mb-4 flex items-center gap-2">
                <span className="material-symbols-outlined text-lg text-primary">info</span>
                {dict.home.aboutThisBlog}
              </h4>
              <ul className="space-y-2.5 text-xs text-on-surface-variant leading-relaxed">
                {dict.home.aboutItems.map((item, i) => (
                  <li key={i} className="flex items-start gap-2">
                    <span className="material-symbols-outlined text-primary text-sm mt-0.5">check_circle</span>
                    {item}
                  </li>
                ))}
              </ul>
              <a
                href={lh("/about")}
                className="mt-5 inline-flex items-center gap-1 text-xs text-primary font-semibold hover:underline"
              >
                더 알아보기
                <span className="material-symbols-outlined text-xs">arrow_forward</span>
              </a>
            </section>
          </aside>
        </div>
      </div>
    </div>
  );
}
