import { notFound } from "next/navigation";
import { Metadata } from "next";
import { getPost, getAllSlugs, getRelatedPosts } from "@/lib/posts";
import { siteConfig, getCategory } from "@/lib/config";
import { breadcrumbSchema, articleSchema, faqSchema, ogImageUrl } from "@/lib/seo";
import { PostCard } from "@/components/PostCard";
import { SourceCard } from "@/components/SourceCard";
import { CoupangAd, CoupangLinkAd, AdSlot } from "@/components/CoupangAd";
import { MDXRemote } from "next-mdx-remote/rsc";
import remarkGfm from "remark-gfm";

// 동적 파라미터 허용
export const dynamicParams = true;

// 정적 생성
export function generateStaticParams() {
  return getAllSlugs().map((slug) => ({ slug }));
}

// SEO 메타데이터
export function generateMetadata({
  params,
}: {
  params: { slug: string };
}): Metadata {
  const post = getPost(params.slug);
  if (!post) return {};

  const { meta } = post;
  const url = `${siteConfig.url}/posts/${meta.slug}`;

  return {
    title: meta.title,
    description: meta.description,
    openGraph: {
      title: meta.title,
      description: meta.description,
      url,
      type: "article",
      publishedTime: meta.date,
      authors: [siteConfig.author],
      tags: meta.tags,
      images: [
        {
          url: meta.thumbnail || ogImageUrl(meta.title, meta.category),
          width: 1200,
          height: 630,
          alt: meta.title,
        },
      ],
    },
    twitter: {
      card: "summary_large_image",
      title: meta.title,
      description: meta.description,
    },
    alternates: {
      canonical: url,
    },
  };
}

function estimateReadingTime(content: string): number {
  const text = content.replace(/<[^>]*>/g, "").replace(/\s+/g, " ");
  const koreanChars = (text.match(/[\uAC00-\uD7AF]/g) || []).length;
  const words = text.split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.ceil((koreanChars / 500 + words / 200) / 2));
}

const difficultyConfig: Record<string, { label: string; color: string }> = {
  beginner: { label: "입문", color: "bg-emerald-100 text-emerald-700" },
  intermediate: { label: "중급", color: "bg-amber-100 text-amber-700" },
  advanced: { label: "심화", color: "bg-rose-100 text-rose-700" },
};

export default function PostPage({ params }: { params: { slug: string } }) {
  const post = getPost(params.slug);
  if (!post) notFound();

  const { meta, content } = post;
  const related = getRelatedPosts(params.slug);
  const category = getCategory(meta.category);
  const readingTime = estimateReadingTime(content);
  const diff = meta.difficulty ? difficultyConfig[meta.difficulty] : null;

  // 구조화 데이터
  const articleJsonLd = articleSchema(meta);
  const breadcrumbJsonLd = breadcrumbSchema([
    { name: "홈", url: siteConfig.url },
    ...(category
      ? [{ name: category.name, url: `${siteConfig.url}/categories/${meta.category}` }]
      : []),
    { name: meta.title, url: `${siteConfig.url}/posts/${meta.slug}` },
  ]);

  // FAQ 자동 추출 (본문에서 Q1/A1 패턴 찾기)
  const faqs: { question: string; answer: string }[] = [];
  const lines = content.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const qMatch = lines[i].match(/^###\s*Q\d*[:.]?\s*(.+)/);
    if (qMatch && i + 1 < lines.length) {
      const aMatch = lines[i + 1].match(/^A\d*[:.]?\s*(.+)/);
      if (aMatch) {
        faqs.push({ question: qMatch[1].trim(), answer: aMatch[1].trim() });
      }
    }
  }
  const faqJsonLd = faqs.length > 0 ? faqSchema(faqs) : null;

  return (
    <>
      {/* 구조화 데이터: Article */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(articleJsonLd) }}
      />
      {/* 구조화 데이터: Breadcrumb */}
      <script
        type="application/ld+json"
        dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }}
      />
      {/* 구조화 데이터: FAQ (리치 스니펫) */}
      {faqJsonLd && (
        <script
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }}
        />
      )}

      <article className="pt-28 pb-20">
        {/* Breadcrumbs */}
        <nav className="max-w-4xl mx-auto px-6 mb-8">
          <ol className="flex items-center gap-2 text-sm text-on-surface-variant">
            <li>
              <a href="/" className="hover:text-primary transition-colors">
                <span className="material-symbols-outlined text-base align-middle">home</span>
              </a>
            </li>
            <li>
              <span className="material-symbols-outlined text-xs text-slate-300">chevron_right</span>
            </li>
            {category && (
              <>
                <li>
                  <a
                    href={`/categories/${meta.category}`}
                    className="hover:text-primary transition-colors"
                  >
                    {category.emoji} {category.name}
                  </a>
                </li>
                <li>
                  <span className="material-symbols-outlined text-xs text-slate-300">chevron_right</span>
                </li>
              </>
            )}
            <li className="text-on-surface font-medium truncate max-w-[200px]">
              {meta.title}
            </li>
          </ol>
        </nav>

        {/* Article Header */}
        <header className="max-w-4xl mx-auto px-6 mb-10">
          <div className="flex items-center gap-2 mb-5 flex-wrap">
            {category && (
              <a
                href={`/categories/${meta.category}`}
                className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold hover:bg-primary/15 transition-colors"
              >
                <span>{category.emoji}</span>
                {category.name}
              </a>
            )}
            {diff && (
              <span className={`px-3 py-1 rounded-full text-xs font-bold ${diff.color}`}>
                {diff.label}
              </span>
            )}
          </div>

          <h1 className="text-3xl lg:text-5xl font-extrabold text-on-surface leading-[1.15] tracking-tight mb-5 font-headline">
            {meta.title}
          </h1>

          <p className="text-lg text-on-surface-variant leading-relaxed mb-6 max-w-2xl">
            {meta.description}
          </p>

          {/* TL;DR */}
          {meta.tldr && (
            <div className="flex items-start gap-3 rounded-xl bg-indigo-50 p-5 border border-indigo-100 mb-6">
              <span className="material-symbols-outlined text-primary text-lg mt-0.5">bolt</span>
              <div>
                <p className="text-xs font-bold text-primary mb-1 uppercase tracking-wider">TL;DR</p>
                <p className="text-sm text-on-surface leading-relaxed">{meta.tldr}</p>
              </div>
            </div>
          )}

          <div className="flex items-center gap-4 text-sm text-on-surface-variant pb-6 border-b border-slate-200/50">
            <div className="flex items-center gap-1.5">
              <span className="material-symbols-outlined text-base">calendar_today</span>
              <time>{meta.date}</time>
            </div>
            <span className="w-1 h-1 bg-slate-300 rounded-full" />
            <div className="flex items-center gap-1.5">
              <span className="material-symbols-outlined text-base">schedule</span>
              <span>{readingTime}분 읽기</span>
            </div>
            <span className="w-1 h-1 bg-slate-300 rounded-full" />
            <span className="font-medium">{siteConfig.author}</span>
          </div>
        </header>

        {/* Featured Image */}
        {meta.thumbnail && (
          <div className="max-w-5xl mx-auto px-6 mb-12">
            <img
              src={meta.thumbnail}
              alt={meta.title}
              className="w-full rounded-2xl shadow-lg object-cover max-h-[500px]"
            />
          </div>
        )}

        {/* Article Body */}
        <div className="max-w-4xl mx-auto px-6">
          <div className="prose max-w-none">
            <MDXRemote source={content} options={{ mdxOptions: { remarkPlugins: [remarkGfm] } }} />
          </div>
        </div>

        {/* 쿠팡 파트너스: 글 관련 상품 추천 */}
        {siteConfig.coupang.enabled && (
          <div className="max-w-4xl mx-auto px-6 mt-12">
            <CoupangLinkAd
              keywords={siteConfig.coupang.productKeywords[meta.category] || siteConfig.coupang.productKeywords["ai-news"]}
              title="이 글과 함께 보면 좋은 상품"
            />
          </div>
        )}

        {/* Source Links */}
        {meta.sources && meta.sources.length > 0 && (
          <section className="max-w-4xl mx-auto px-6 mt-16">
            <div className="flex items-center gap-2 mb-6">
              <span className="material-symbols-outlined text-primary text-2xl">link</span>
              <h2 className="text-2xl font-extrabold text-on-surface font-headline">
                참고 자료
              </h2>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              {meta.sources.map((source, i) => (
                <SourceCard key={i} source={source} />
              ))}
            </div>
          </section>
        )}

        {/* Disclaimer */}
        <div className="max-w-4xl mx-auto px-6 mt-12">
          <div className="flex items-start gap-3 rounded-xl bg-slate-50 p-5 border border-slate-100">
            <span className="material-symbols-outlined text-on-surface-variant text-lg mt-0.5">info</span>
            <div className="text-xs text-on-surface-variant leading-relaxed space-y-1">
              <p>{siteConfig.disclaimer}</p>
              {siteConfig.coupang.enabled && (
                <p>{siteConfig.coupang.disclaimer}</p>
              )}
            </div>
          </div>
        </div>

        {/* Tags */}
        {meta.tags.length > 0 && (
          <div className="max-w-4xl mx-auto px-6 mt-10">
            <div className="flex flex-wrap gap-2">
              {meta.tags.map((tag) => (
                <span
                  key={tag}
                  className="px-4 py-2 rounded-full bg-slate-50 border border-slate-100 text-sm text-on-surface-variant"
                >
                  #{tag}
                </span>
              ))}
            </div>
          </div>
        )}

        {/* 쿠팡 광고: 관련 글 위 */}
        {siteConfig.coupang.enabled && (
          <div className="max-w-4xl mx-auto px-6 mt-10">
            <AdSlot label={false}>
              <CoupangAd {...siteConfig.coupang.ads.postMid} />
            </AdSlot>
          </div>
        )}

        {/* Related Posts */}
        {related.length > 0 && (
          <section className="max-w-7xl mx-auto px-6 mt-20 pt-12 border-t border-slate-200/50">
            <div className="flex items-center justify-between mb-8">
              <h2 className="text-2xl font-extrabold text-on-surface font-headline">
                관련 글 더보기
              </h2>
              <a
                href="/posts"
                className="text-sm text-primary font-bold hover:underline flex items-center gap-1"
              >
                전체 보기
                <span className="material-symbols-outlined text-sm">arrow_forward</span>
              </a>
            </div>
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {related.map((p) => (
                <PostCard key={p.slug} post={p} compact />
              ))}
            </div>
          </section>
        )}
      </article>
    </>
  );
}
