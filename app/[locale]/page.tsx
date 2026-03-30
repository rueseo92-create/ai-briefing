import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";
import { PostCard } from "@/components/PostCard";
import { CoupangLinkAd, CoupangSidebarAd } from "@/components/CoupangAd";
import NewsletterForm from "@/components/NewsletterForm";
import { getDictionary, localizedHref, defaultLocale, type Locale } from "@/lib/i18n";

/* 카테고리 액센트 컬러 */
const catColors: Record<string, { bg: string; text: string }> = {
  "ai-news": { bg: "bg-indigo-500", text: "text-indigo-500" },
  "side-hustle": { bg: "bg-emerald-600", text: "text-emerald-600" },
  "ai-tools": { bg: "bg-cyan-600", text: "text-cyan-600" },
  "digital-nomad": { bg: "bg-violet-600", text: "text-violet-600" },
  marketing: { bg: "bg-amber-600", text: "text-amber-600" },
};

export default async function Home({ params }: { params: { locale: string } }) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);
  const lh = (path: string) => localizedHref(path, locale);

  const posts = getAllPosts();
  const featured = posts[0];
  const leadStory = posts[1];
  const gridPosts = posts.slice(2, 8);
  const hasMore = posts.length > 8;

  return (
    <div>
      {/* ═══════════════════════════════════════════
          HERO — 커스텀 그라데이션, 스톡 사진 없음
          ═══════════════════════════════════════════ */}
      <section className="relative min-h-[92vh] flex items-center overflow-hidden grain">
        {/* 배경 그라데이션 */}
        <div className="absolute inset-0 bg-gradient-to-br from-[#0F0B2E] via-[#1a1145] to-[#0c1a3a]" />
        {/* 장식 글로우 */}
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_20%_50%,rgba(99,102,241,0.12),transparent_60%)]" />
        <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_80%_20%,rgba(139,92,246,0.08),transparent_50%)]" />

        <div className="relative z-10 w-full max-w-7xl mx-auto px-6 lg:px-12 py-28 lg:py-0">
          <div className="grid lg:grid-cols-5 gap-12 lg:gap-16 items-center">
            {/* 왼쪽: 브랜드 메시지 (3/5) */}
            <div className="lg:col-span-3">
              {/* 오버라인 */}
              <div className="flex items-center gap-3 mb-8">
                <div className="w-12 h-px bg-gradient-to-r from-indigo-500/60 to-transparent" />
                <span className="text-[11px] font-bold tracking-[0.25em] uppercase text-indigo-400/80">AI Briefing</span>
              </div>

              <h1 className="text-5xl sm:text-6xl lg:text-7xl xl:text-8xl font-extrabold text-white leading-[0.95] tracking-tight font-headline mb-8">
                AI의 오늘을<br />
                <span className="bg-gradient-to-r from-white to-indigo-200 bg-clip-text text-transparent">한눈에.</span>
              </h1>

              <p className="text-lg text-white/50 leading-relaxed max-w-lg mb-10">
                {dict.meta.siteDescription}
              </p>

              {/* 스탯 */}
              <div className="flex items-center gap-8 lg:gap-10">
                {[
                  { num: `${posts.length}+`, label: "Articles" },
                  { num: "Daily", label: "Updates" },
                  { num: `${siteConfig.categories.length}`, label: "Topics" },
                ].map((stat, i) => (
                  <div key={stat.label} className="flex items-center gap-8 lg:gap-10">
                    {i > 0 && <div className="w-px h-8 bg-white/10 -ml-8 lg:-ml-10" />}
                    <div>
                      <p className="text-2xl font-extrabold text-white font-headline">{stat.num}</p>
                      <p className="text-[11px] text-white/30 mt-0.5 tracking-wide">{stat.label}</p>
                    </div>
                  </div>
                ))}
              </div>

              {/* CTA */}
              <div className="mt-12">
                <a
                  href="#latest"
                  className="inline-flex items-center gap-2.5 px-8 py-4 bg-white text-[#0F0B2E] font-bold text-sm rounded-full hover:bg-indigo-100 transition-all duration-300 shadow-[0_0_40px_rgba(99,102,241,0.15)] hover:shadow-[0_0_60px_rgba(99,102,241,0.25)] hover:scale-[1.02] active:scale-[0.98]"
                >
                  브리핑 시작하기
                  <span className="material-symbols-outlined text-base">arrow_downward</span>
                </a>
              </div>
            </div>

            {/* 오른쪽: Featured 카드 (2/5) */}
            {featured && (
              <div className="lg:col-span-2">
                <a
                  href={lh(`/posts/${featured.slug}`)}
                  className="group block rounded-2xl bg-white/[0.06] backdrop-blur-xl border border-white/[0.08] p-6 lg:p-8 hover:bg-white/[0.1] hover:border-white/[0.12] transition-all duration-500 shadow-[0_8px_40px_rgba(0,0,0,0.2)]"
                >
                  <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full bg-indigo-500/20 border border-indigo-400/20 text-indigo-300 text-[11px] font-bold tracking-widest uppercase mb-5">
                    <span className="w-1.5 h-1.5 bg-indigo-400 rounded-full animate-pulse" />
                    {dict.home.latest}
                  </div>
                  <h2 className="text-xl lg:text-2xl font-bold text-white leading-snug font-headline group-hover:text-indigo-200 transition-colors duration-300 mb-4 line-clamp-3">
                    {featured.title}
                  </h2>
                  <p className="text-sm text-white/40 leading-relaxed line-clamp-2 mb-5">
                    {featured.description}
                  </p>
                  <div className="flex items-center gap-3 text-xs text-white/30">
                    <span>{featured.date}</span>
                    <span className="w-1 h-1 bg-white/20 rounded-full" />
                    <span className="text-indigo-300/70">{featured.category}</span>
                  </div>
                  <div className="mt-5 pt-5 border-t border-white/[0.06] flex items-center gap-2 text-xs font-semibold text-indigo-300/60 group-hover:text-indigo-300 transition-colors">
                    읽어보기
                    <span className="material-symbols-outlined text-xs group-hover:translate-x-0.5 transition-transform">arrow_forward</span>
                  </div>
                </a>
              </div>
            )}
          </div>
        </div>

        {/* 스크롤 인디케이터 */}
        <div className="absolute bottom-8 left-1/2 -translate-x-1/2 text-white/15 animate-bounce hidden lg:block">
          <span className="material-symbols-outlined text-2xl">expand_more</span>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          CATEGORY PILLS — 경량 필 네비게이션
          ═══════════════════════════════════════════ */}
      <section className="relative z-20 -mt-5">
        <div className="max-w-7xl mx-auto px-6 lg:px-12">
          <div className="flex items-center justify-center gap-2.5 overflow-x-auto no-scrollbar snap-pills py-3">
            <a
              href={lh("/")}
              className="flex-shrink-0 px-5 py-2.5 rounded-full bg-primary text-white font-semibold text-sm shadow-md shadow-primary/20 transition-all duration-200"
            >
              {dict.home.all}
            </a>
            {siteConfig.categories.map((cat) => (
              <a
                key={cat.slug}
                href={lh(`/categories/${cat.slug}`)}
                className="flex-shrink-0 inline-flex items-center gap-1.5 px-5 py-2.5 rounded-full bg-white border border-slate-200 text-sm font-medium text-slate-600 shadow-sm hover:bg-primary hover:text-white hover:border-primary hover:shadow-lg hover:shadow-primary/20 hover:scale-[1.03] transition-all duration-200"
              >
                <span>{cat.emoji}</span>
                {cat.name}
              </a>
            ))}
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          INLINE NEWSLETTER CTA
          ═══════════════════════════════════════════ */}
      <section className="mt-12 mb-4">
        <div className="max-w-7xl mx-auto px-6 lg:px-12">
          <div className="rounded-2xl bg-gradient-to-r from-indigo-600 via-violet-600 to-indigo-700 p-6 lg:p-8 relative overflow-hidden">
            {/* 장식 */}
            <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_90%_50%,rgba(255,255,255,0.08),transparent_60%)]" />
            <div className="relative flex flex-col lg:flex-row items-start lg:items-center justify-between gap-6">
              <div className="flex-1 min-w-0">
                <h3 className="text-lg font-bold text-white font-headline mb-1">{dict.home.newsletter}</h3>
                <p className="text-sm text-white/60">{dict.home.newsletterDesc}</p>
              </div>
              <NewsletterForm
                placeholder={dict.home.emailPlaceholder}
                buttonText={dict.home.subscribe}
              />
            </div>
          </div>
        </div>
      </section>

      {siteConfig.coupang.enabled && (
        <div className="max-w-7xl mx-auto px-6 lg:px-12 my-6">
          <CoupangLinkAd
            keywords={["삼성 갤럭시북4 프로 노트북", "로지텍 MX Keys S 키보드", "LG 울트라와이드 모니터", "에어팟 프로 2세대"]}
            title={dict.home.coupangTitle}
          />
        </div>
      )}

      {/* ═══════════════════════════════════════════
          EDITORIAL CONTENT GRID
          ═══════════════════════════════════════════ */}
      <section id="latest" className="pt-16 pb-8">
        <div className="max-w-7xl mx-auto px-6 lg:px-12">
          {/* 섹션 헤더 */}
          <div className="flex items-end justify-between mb-10">
            <div>
              <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-2">Latest Articles</p>
              <h2 className="text-2xl lg:text-3xl font-bold text-on-surface font-headline">최신 브리핑</h2>
            </div>
            <a href={lh("/posts")} className="text-sm font-semibold text-primary hover:text-indigo-700 transition-colors flex items-center gap-1">
              {dict.home.viewAllPosts}
              <span className="material-symbols-outlined text-sm">arrow_forward</span>
            </a>
          </div>

          <div className="flex flex-col lg:flex-row gap-10">
            {/* 메인 콘텐츠 */}
            <div className="flex-1 min-w-0">
              {/* 리드 스토리 (풀 와이드 가로형) */}
              {leadStory && (
                <div className="mb-8">
                  <PostCard post={leadStory} featured locale={locale} />
                </div>
              )}

              {/* 그리드 */}
              {gridPosts.length > 0 && (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
                  {gridPosts.map((post) => (
                    <PostCard key={post.slug} post={post} locale={locale} />
                  ))}
                </div>
              )}

              {posts.length === 0 && (
                <div className="py-20 text-center">
                  <p className="text-6xl mb-4">🤖</p>
                  <h2 className="text-xl font-bold text-on-surface mb-2 font-headline">{dict.home.noPosts}</h2>
                  <p className="text-on-surface-variant text-sm">{dict.home.noPostsDesc}</p>
                </div>
              )}

              {hasMore && (
                <div className="mt-14 text-center">
                  <a
                    href={lh("/posts")}
                    className="inline-flex items-center gap-2.5 px-10 py-4 bg-white text-on-surface font-bold text-sm rounded-full border border-slate-200 hover:border-primary hover:text-primary hover:shadow-lg hover:shadow-primary/10 transition-all duration-300"
                  >
                    {dict.home.viewAllPosts}
                    <span className="material-symbols-outlined text-sm">arrow_forward</span>
                  </a>
                </div>
              )}
            </div>

            {/* 사이드바 */}
            <aside className="w-full lg:w-[300px] flex-shrink-0 space-y-6 lg:sticky lg:top-24 lg:self-start">
              {/* 태그 */}
              <div>
                <h4 className="text-xs font-bold tracking-[0.15em] uppercase text-slate-400 mb-4">
                  {dict.home.popularKeywords}
                </h4>
                <div className="flex flex-wrap gap-2">
                  {posts
                    .flatMap((p) => p.tags)
                    .filter((v, i, a) => a.indexOf(v) === i)
                    .slice(0, 10)
                    .map((tag) => (
                      <a
                        key={tag}
                        href={lh(`/search?tag=${encodeURIComponent(tag)}`)}
                        className="px-3 py-1.5 rounded-full bg-white border border-slate-200 text-xs font-medium text-slate-500 hover:border-primary hover:text-primary hover:bg-primary/5 transition-all duration-200"
                      >
                        #{tag}
                      </a>
                    ))}
                </div>
              </div>

              {siteConfig.coupang.enabled && (
                <CoupangSidebarAd keywords={["챗GPT 활용법 도서", "삼성 갤럭시북4 프로 노트북", "로지텍 MX Master 3S", "LG 울트라와이드 모니터 34인치", "에어팟 프로 2세대"]} />
              )}

              {/* 소개 */}
              <div className="rounded-2xl bg-white ring-1 ring-slate-200/60 p-5">
                <h4 className="text-xs font-bold tracking-[0.15em] uppercase text-slate-400 mb-3">
                  {dict.home.aboutThisBlog}
                </h4>
                <ul className="space-y-2 text-xs text-on-surface-variant leading-relaxed">
                  {dict.home.aboutItems.map((item, i) => (
                    <li key={i} className="flex items-start gap-2">
                      <span className="material-symbols-outlined text-primary text-sm mt-0.5">check_circle</span>
                      {item}
                    </li>
                  ))}
                </ul>
              </div>
            </aside>
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          CATEGORY SHOWCASE — 풀 와이드 탐색 섹션
          ═══════════════════════════════════════════ */}
      <section className="py-20 lg:py-24 bg-slate-50">
        <div className="max-w-7xl mx-auto px-6 lg:px-12">
          <div className="text-center mb-14">
            <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-2">Explore Topics</p>
            <h2 className="text-2xl lg:text-3xl font-bold text-on-surface font-headline">관심 있는 주제를 골라보세요</h2>
          </div>

          <div className="grid grid-cols-2 lg:grid-cols-5 gap-4">
            {siteConfig.categories.map((cat) => {
              const catPosts = posts.filter((p) => p.category === cat.slug);
              const colors = catColors[cat.slug] || catColors["ai-news"];
              return (
                <a
                  key={cat.slug}
                  href={lh(`/categories/${cat.slug}`)}
                  className={`group relative rounded-2xl overflow-hidden h-44 lg:h-52 ${colors.bg}`}
                >
                  {/* 오버레이 패턴 */}
                  <div className="absolute inset-0 bg-[radial-gradient(ellipse_at_30%_20%,rgba(255,255,255,0.15),transparent_60%)]" />
                  <div className="absolute inset-0 bg-gradient-to-t from-black/30 to-transparent" />
                  {/* 콘텐츠 */}
                  <div className="absolute inset-0 flex flex-col justify-end p-5">
                    <span className="text-3xl mb-2 group-hover:scale-110 transition-transform duration-300">{cat.emoji}</span>
                    <h3 className="text-base font-bold text-white font-headline">{cat.name}</h3>
                    <p className="text-[11px] text-white/60 mt-1">{catPosts.length}개의 글</p>
                  </div>
                  {/* 화살표 (호버) */}
                  <div className="absolute top-4 right-4 opacity-0 group-hover:opacity-100 transition-opacity duration-300">
                    <span className="material-symbols-outlined text-white/80 text-lg">arrow_forward</span>
                  </div>
                </a>
              );
            })}
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          TRUST BAR — 소셜 프루프
          ═══════════════════════════════════════════ */}
      <section className="py-14 border-b border-slate-100">
        <div className="max-w-5xl mx-auto px-6 lg:px-12">
          <div className="flex flex-wrap items-center justify-center gap-10 lg:gap-16">
            {[
              { num: `${posts.length}+`, label: "발행된 글" },
              { num: `${siteConfig.categories.length}`, label: "콘텐츠 카테고리" },
              { num: "24/7", label: "자동 발행" },
              { num: "100%", label: "SEO 최적화" },
            ].map((stat, i) => (
              <div key={stat.label} className="flex items-center gap-10 lg:gap-16">
                {i > 0 && <div className="w-px h-10 bg-slate-200 -ml-10 lg:-ml-16 hidden sm:block" />}
                <div className="text-center">
                  <p className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline">{stat.num}</p>
                  <p className="text-xs text-slate-400 mt-1 tracking-wide">{stat.label}</p>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ═══════════════════════════════════════════
          BUSINESS CTA — 대행 서비스 프로모션
          ═══════════════════════════════════════════ */}
      <section className="py-20 lg:py-28">
        <div className="max-w-7xl mx-auto px-6 lg:px-12">
          <div className="grid lg:grid-cols-2 gap-12 lg:gap-20 items-center">
            {/* 텍스트 */}
            <div>
              <p className="text-xs font-bold tracking-[0.2em] uppercase text-primary mb-3">For Business</p>
              <h2 className="text-3xl lg:text-4xl font-bold text-on-surface font-headline mb-5 leading-tight">
                직접 하기<br />어려우시다면
              </h2>
              <p className="text-on-surface-variant leading-relaxed max-w-lg mb-8">
                AI 블로그 구축, SEO 최적화, 콘텐츠 자동화 — 이 블로그에서 방법을 다 알려드리지만,
                바쁘시면 저희가 대신 해드립니다.
              </p>
              <div className="flex flex-wrap items-center gap-4">
                <a
                  href={lh("/business")}
                  className="inline-flex items-center gap-2 px-7 py-3.5 bg-primary text-white font-bold text-sm rounded-full hover:bg-indigo-700 transition-colors shadow-lg shadow-primary/20"
                >
                  서비스 살펴보기
                  <span className="material-symbols-outlined text-base">arrow_forward</span>
                </a>
                <a
                  href="mailto:contact@seroai.xyz"
                  className="inline-flex items-center gap-1.5 text-sm font-semibold text-primary hover:text-indigo-700 transition-colors"
                >
                  또는 바로 문의하기
                  <span className="material-symbols-outlined text-sm">arrow_forward</span>
                </a>
              </div>
            </div>

            {/* 서비스 카드 */}
            <div className="rounded-2xl bg-slate-50 border border-slate-200/80 p-8 shadow-[0_8px_30px_rgba(0,0,0,0.04)]">
              <div className="space-y-5">
                {[
                  { icon: "edit_note", title: "AI 블로그 자동화", desc: "매일 SEO 최적화된 글 자동 발행" },
                  { icon: "travel_explore", title: "SEO 최적화", desc: "기술적 SEO 분석 및 전면 적용" },
                  { icon: "web", title: "웹사이트 구축", desc: "기획부터 배포까지 원스톱" },
                  { icon: "smart_toy", title: "AI 파이프라인", desc: "크롤링 → 생성 → 발행 전체 자동화" },
                ].map((item) => (
                  <div key={item.title} className="flex items-start gap-3.5">
                    <div className="w-9 h-9 rounded-xl bg-primary/10 flex items-center justify-center flex-shrink-0">
                      <span className="material-symbols-outlined text-primary text-lg">{item.icon}</span>
                    </div>
                    <div>
                      <h4 className="text-sm font-bold text-on-surface">{item.title}</h4>
                      <p className="text-xs text-slate-400 mt-0.5">{item.desc}</p>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          </div>
        </div>
      </section>
    </div>
  );
}
