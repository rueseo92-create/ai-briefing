import { Metadata } from "next";
import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";
import { PostCard } from "@/components/PostCard";
import { CoupangAd, CoupangSidebarAd, AdSlot } from "@/components/CoupangAd";

export const metadata: Metadata = {
  title: siteConfig.defaultTitle,
  description: siteConfig.description,
  openGraph: {
    title: siteConfig.defaultTitle,
    description: siteConfig.description,
    url: siteConfig.url,
    type: "website",
    images: [
      {
        url: `${siteConfig.url}/api/og?title=${encodeURIComponent(siteConfig.name)}&category=홈`,
        width: 1200,
        height: 630,
        alt: siteConfig.name,
      },
    ],
  },
};

export default function Home() {
  const posts = getAllPosts();
  const featured = posts[0];
  const recent = posts.slice(1, 7);

  return (
    <div className="pt-32 pb-20 max-w-7xl mx-auto px-6 lg:px-12">
      {/* Hero Section */}
      {featured ? (
        <section className="mb-16">
          <a
            href={`/posts/${featured.slug}`}
            className="group relative block overflow-hidden rounded-2xl bg-gradient-to-br from-indigo-50 via-white to-cyan-50 p-12 lg:p-20 shadow-sm border border-indigo-100/50 hover:shadow-lg transition-all"
          >
            <div className="max-w-2xl relative z-10">
              <span className="inline-flex items-center px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold mb-6 tracking-wider uppercase">
                Latest
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
                    <span className="px-2 py-0.5 rounded bg-slate-100 text-xs">
                      {featured.difficulty === "beginner" ? "입문" : featured.difficulty === "intermediate" ? "중급" : "심화"}
                    </span>
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
                <span className="inline-flex items-center justify-center w-12 h-12 rounded-xl bg-primary text-white text-xl font-bold">
                  AI
                </span>
                <h1 className="text-4xl lg:text-6xl font-extrabold text-on-surface leading-[1.1] tracking-tight font-headline">
                  브리핑
                </h1>
              </div>
              <p className="text-lg text-on-surface-variant leading-relaxed">
                {siteConfig.description}
              </p>
              <p className="mt-4 text-sm text-slate-400">
                곧 첫 번째 글이 올라옵니다.
              </p>
            </div>
          </div>
        </section>
      )}

      {/* 쿠팡 광고: 히어로 아래 */}
      {siteConfig.coupang.enabled && (
        <AdSlot className="mb-8">
          <CoupangAd {...siteConfig.coupang.ads.homeTop} />
        </AdSlot>
      )}

      {/* Category Filter Bar */}
      <section className="mb-12">
        <div className="flex items-center gap-3 overflow-x-auto pb-4 no-scrollbar">
          <a
            href="/"
            className="px-6 py-2.5 rounded-full bg-primary text-on-primary font-bold text-sm shadow-md shadow-primary/20 whitespace-nowrap"
          >
            전체
          </a>
          {siteConfig.categories.map((cat) => (
            <a
              key={cat.slug}
              href={`/categories/${cat.slug}`}
              className="px-6 py-2.5 rounded-full bg-surface-container-low text-on-surface-variant hover:bg-primary/10 hover:text-primary transition-colors font-medium text-sm whitespace-nowrap"
            >
              {cat.emoji} {cat.name}
            </a>
          ))}
        </div>
      </section>

      {/* Main Content */}
      <div className="flex flex-col lg:flex-row gap-12">
        {/* Left: Post Grid */}
        <div className="flex-1">
          {recent.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
              {recent.map((post) => (
                <PostCard key={post.slug} post={post} />
              ))}
            </div>
          ) : posts.length === 0 ? (
            <div className="py-20 text-center">
              <p className="text-6xl mb-4">🤖</p>
              <h2 className="text-xl font-bold text-on-surface mb-2 font-headline">
                아직 글이 없습니다
              </h2>
              <p className="text-on-surface-variant text-sm">
                파이프라인을 실행해서 AI 관련 콘텐츠를 생성해보세요
              </p>
            </div>
          ) : null}

          {posts.length > 6 && (
            <div className="mt-16 text-center">
              <a
                href="/posts"
                className="inline-flex items-center gap-2 px-8 py-3 bg-slate-100 text-on-surface font-bold rounded-lg hover:bg-slate-200 transition-colors"
              >
                전체 글 보기
                <span className="material-symbols-outlined text-sm">arrow_forward</span>
              </a>
            </div>
          )}
        </div>

        {/* Right: Sidebar */}
        <aside className="w-full lg:w-[320px] space-y-12">
          {/* Popular Tags */}
          <section>
            <h4 className="text-sm font-bold text-on-surface mb-6 flex items-center gap-2">
              <span className="material-symbols-outlined text-lg text-primary">tag</span>
              인기 키워드
            </h4>
            <div className="flex flex-wrap gap-2">
              {posts
                .flatMap((p) => p.tags)
                .filter((v, i, a) => a.indexOf(v) === i)
                .slice(0, 10)
                .map((tag) => (
                  <span
                    key={tag}
                    className="px-3 py-1.5 bg-white border border-slate-200 rounded-md text-xs text-on-surface-variant hover:border-primary hover:text-primary transition-all cursor-pointer"
                  >
                    #{tag}
                  </span>
                ))}
            </div>
          </section>

          {/* 쿠팡 파트너스: 사이드바 */}
          {siteConfig.coupang.enabled && (
            <CoupangSidebarAd
              keywords={[
                "AI 관련 도서 베스트셀러",
                "프로그래밍 키보드 추천",
                "노트북 거치대 인기",
                "무선 마우스 가성비",
                "모니터 암 추천",
              ]}
            />
          )}

          {/* Newsletter Signup */}
          <section className="bg-gradient-to-b from-indigo-50 to-white rounded-2xl p-8 border border-indigo-100/50">
            <h4 className="text-lg font-bold text-on-surface mb-2 font-headline">
              AI 브리핑 뉴스레터
            </h4>
            <p className="text-sm text-on-surface-variant mb-6 leading-relaxed">
              매주 AI 트렌드와 정부사업 정보를 정리해서 보내드립니다.
            </p>
            <form className="space-y-3" action="#">
              <input
                className="w-full px-4 py-3 rounded-lg border border-slate-200 bg-white text-sm focus:ring-2 focus:ring-primary/20 focus:border-primary shadow-sm"
                placeholder="이메일 주소를 입력하세요"
                type="email"
              />
              <button className="w-full py-3 bg-primary text-on-primary font-bold rounded-lg hover:bg-primary-container transition-colors shadow-lg shadow-primary/20">
                구독하기
              </button>
            </form>
            <p className="mt-4 text-[10px] text-slate-400 text-center">
              스팸 걱정 없이 언제든 해지 가능합니다.
            </p>
          </section>

          {/* Quick Info */}
          <section className="bg-slate-50 rounded-xl p-6 border border-slate-100">
            <h4 className="text-sm font-bold text-on-surface mb-4 flex items-center gap-2">
              <span className="material-symbols-outlined text-lg text-secondary">info</span>
              이 블로그는
            </h4>
            <ul className="space-y-2 text-xs text-on-surface-variant leading-relaxed">
              <li className="flex items-start gap-2">
                <span className="text-primary mt-0.5">&#10003;</span>
                AI 뉴스를 쉬운 한국어로 정리
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-0.5">&#10003;</span>
                정부 AI 사업/지원금 정보 크롤링
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-0.5">&#10003;</span>
                실전 AI 도구 사용법 가이드
              </li>
              <li className="flex items-start gap-2">
                <span className="text-primary mt-0.5">&#10003;</span>
                Google 검색 최적화(SEO) 콘텐츠
              </li>
            </ul>
          </section>
        </aside>
      </div>
    </div>
  );
}
