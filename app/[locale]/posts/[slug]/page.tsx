import { notFound } from "next/navigation";
import { Metadata } from "next";
import { getPost, getAllPosts, getAllSlugs, getRelatedPosts } from "@/lib/posts";
import { siteConfig, getCategory } from "@/lib/config";
import { breadcrumbSchema, articleSchema, faqSchema, ogImageUrl } from "@/lib/seo";
import { PostCard } from "@/components/PostCard";
import { SourceCard } from "@/components/SourceCard";
import { CoupangLinkAd } from "@/components/CoupangAd";
import { ReadingProgress } from "@/components/ReadingProgress";
import { TableOfContents } from "@/components/TableOfContents";
import { ShareButtons } from "@/components/ShareButtons";
import { MDXRemote } from "next-mdx-remote/rsc";
import remarkGfm from "remark-gfm";
import { getDictionary, localizedHref, locales, defaultLocale, type Locale } from "@/lib/i18n";

export const dynamicParams = true;

export function generateStaticParams() {
  const slugs = getAllSlugs();
  return locales.flatMap((locale) => slugs.map((slug) => ({ locale, slug })));
}

export function generateMetadata({ params }: { params: { locale: string; slug: string } }): Metadata {
  const locale = (params.locale || defaultLocale) as Locale;
  const post = getPost(params.slug);
  if (!post) return {};
  const { meta } = post;
  const lp = locale === defaultLocale ? "" : `/${locale}`;
  const url = `${siteConfig.url}${lp}/posts/${meta.slug}`;

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
      images: [{ url: meta.thumbnail || ogImageUrl(meta.title, meta.category), width: 1200, height: 630, alt: meta.title }],
    },
    twitter: { card: "summary_large_image", title: meta.title, description: meta.description },
    alternates: {
      canonical: url,
      languages: {
        ko: `${siteConfig.url}/posts/${meta.slug}`,
        en: `${siteConfig.url}/en/posts/${meta.slug}`,
        zh: `${siteConfig.url}/zh/posts/${meta.slug}`,
        ja: `${siteConfig.url}/ja/posts/${meta.slug}`,
        es: `${siteConfig.url}/es/posts/${meta.slug}`,
      },
    },
  };
}

function estimateReadingTime(content: string): number {
  const text = content.replace(/<[^>]*>/g, "").replace(/\s+/g, " ");
  const koreanChars = (text.match(/[\uAC00-\uD7AF]/g) || []).length;
  const words = text.split(/\s+/).filter(Boolean).length;
  return Math.max(1, Math.ceil((koreanChars / 500 + words / 200) / 2));
}

export default async function PostPage({ params }: { params: { locale: string; slug: string } }) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);
  const lh = (path: string) => localizedHref(path, locale);

  const post = getPost(params.slug);
  if (!post) notFound();

  const { meta, content } = post;
  const related = getRelatedPosts(params.slug);
  const category = getCategory(meta.category);
  const readingTime = estimateReadingTime(content);

  // Prev/Next navigation
  const allPosts = getAllPosts(locale as "ko" | "en");
  const currentIdx = allPosts.findIndex((p) => p.slug === params.slug);
  const prevPost = currentIdx < allPosts.length - 1 ? allPosts[currentIdx + 1] : null;
  const nextPost = currentIdx > 0 ? allPosts[currentIdx - 1] : null;

  const lp = locale === defaultLocale ? "" : `/${locale}`;
  const postUrl = `${siteConfig.url}${lp}/posts/${meta.slug}`;

  const diffConfig: Record<string, { label: string; color: string }> = {
    beginner: { label: dict.post.beginner, color: "bg-emerald-100 text-emerald-700" },
    intermediate: { label: dict.post.intermediate, color: "bg-amber-100 text-amber-700" },
    advanced: { label: dict.post.advanced, color: "bg-rose-100 text-rose-700" },
  };
  const diff = meta.difficulty ? diffConfig[meta.difficulty] : null;

  const articleJsonLd = articleSchema(meta);
  const breadcrumbJsonLd = breadcrumbSchema([
    { name: dict.post.home, url: siteConfig.url },
    ...(category ? [{ name: category.name, url: `${siteConfig.url}/categories/${meta.category}` }] : []),
    { name: meta.title, url: `${siteConfig.url}/posts/${meta.slug}` },
  ]);

  const faqs: { question: string; answer: string }[] = [];
  const lines = content.split("\n");
  for (let i = 0; i < lines.length; i++) {
    const qMatch = lines[i].match(/^###\s*Q\d*[:.]?\s*(.+)/);
    if (qMatch && i + 1 < lines.length) {
      const aMatch = lines[i + 1].match(/^A\d*[:.]?\s*(.+)/);
      if (aMatch) faqs.push({ question: qMatch[1].trim(), answer: aMatch[1].trim() });
    }
  }
  const faqJsonLd = faqs.length > 0 ? faqSchema(faqs) : null;

  return (
    <>
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(articleJsonLd) }} />
      <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(breadcrumbJsonLd) }} />
      {faqJsonLd && <script type="application/ld+json" dangerouslySetInnerHTML={{ __html: JSON.stringify(faqJsonLd) }} />}

      <ReadingProgress />
      <TableOfContents />

      <article className="pt-28 pb-20" data-category={meta.category}>
        {/* Breadcrumbs */}
        <nav className="max-w-4xl mx-auto px-6 mb-8">
          <ol className="flex items-center gap-2 text-sm text-on-surface-variant">
            <li><a href={lh("/")} className="hover:text-primary transition-colors"><span className="material-symbols-outlined text-base align-middle">home</span></a></li>
            <li><span className="material-symbols-outlined text-xs text-slate-300">chevron_right</span></li>
            {category && (
              <>
                <li><a href={lh(`/categories/${meta.category}`)} className="hover:text-primary transition-colors">{category.emoji} {category.name}</a></li>
                <li><span className="material-symbols-outlined text-xs text-slate-300">chevron_right</span></li>
              </>
            )}
            <li className="text-on-surface font-medium truncate max-w-[200px]">{meta.title}</li>
          </ol>
        </nav>

        {/* Header */}
        <header className="max-w-4xl mx-auto px-6 mb-10">
          <div className="flex items-center gap-2 mb-5 flex-wrap">
            {category && (
              <a href={lh(`/categories/${meta.category}`)} className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-primary/10 text-primary text-xs font-bold hover:bg-primary/15 transition-colors">
                <span>{category.emoji}</span>{category.name}
              </a>
            )}
            {diff && <span className={`px-3 py-1 rounded-full text-xs font-bold ${diff.color}`}>{diff.label}</span>}
          </div>
          <h1 className="text-3xl lg:text-5xl font-extrabold text-on-surface leading-[1.15] tracking-tight mb-5 font-headline">{meta.title}</h1>
          <p className="text-lg text-on-surface-variant leading-relaxed mb-6 max-w-2xl">{meta.description}</p>

          {meta.tldr && (
            <div className="flex items-start gap-3 rounded-xl bg-indigo-50 p-5 border border-indigo-100 mb-6">
              <span className="material-symbols-outlined text-primary text-lg mt-0.5">bolt</span>
              <div>
                <p className="text-xs font-bold text-primary mb-1 uppercase tracking-wider">TL;DR</p>
                <p className="text-sm text-on-surface leading-relaxed">{meta.tldr}</p>
              </div>
            </div>
          )}

          <div className="flex items-center justify-between pb-6 border-b border-slate-200/50">
            <div className="flex items-center gap-4 text-sm text-on-surface-variant">
              <div className="flex items-center gap-1.5">
                <span className="material-symbols-outlined text-base">calendar_today</span>
                <time>{meta.date}</time>
              </div>
              <span className="w-1 h-1 bg-slate-300 rounded-full" />
              <div className="flex items-center gap-1.5">
                <span className="material-symbols-outlined text-base">schedule</span>
                <span>{readingTime}{dict.post.readingTime}</span>
              </div>
              <span className="w-1 h-1 bg-slate-300 rounded-full hidden sm:block" />
              <span className="font-medium hidden sm:inline">{siteConfig.author}</span>
            </div>
            <ShareButtons url={postUrl} title={meta.title} description={meta.description} />
          </div>
        </header>

        {meta.thumbnail && (
          <div className="max-w-5xl mx-auto px-6 mb-12">
            <img src={meta.thumbnail} alt={meta.title} className="w-full rounded-2xl shadow-lg object-cover max-h-[500px]" />
          </div>
        )}

        <div className="max-w-4xl mx-auto px-6">
          <div className="prose max-w-none">
            <MDXRemote source={content} options={{ mdxOptions: { remarkPlugins: [[remarkGfm, { singleTilde: false }]] } }} />
          </div>
        </div>

        {siteConfig.coupang.enabled && (
          <div className="max-w-4xl mx-auto px-6 mt-12">
            <CoupangLinkAd
              keywords={(() => {
                const tagMap = siteConfig.coupang.tagProductMap;
                const matched = meta.tags.map((tag) => { const key = Object.keys(tagMap).find((k) => tag.includes(k) || k.includes(tag)); return key ? tagMap[key] : null; }).filter((v): v is string => v !== null);
                const catDefaults = siteConfig.coupang.productKeywords[meta.category] || siteConfig.coupang.productKeywords["ai-news"];
                return Array.from(new Set([...matched, ...catDefaults])).slice(0, 4);
              })()}
              title={dict.post.coupangReaderTitle}
            />
          </div>
        )}

        {meta.sources && meta.sources.length > 0 && (
          <section className="max-w-4xl mx-auto px-6 mt-16">
            <div className="flex items-center gap-2 mb-6">
              <span className="material-symbols-outlined text-primary text-2xl">link</span>
              <h2 className="text-2xl font-extrabold text-on-surface font-headline">{dict.post.references}</h2>
            </div>
            <div className="grid gap-3 sm:grid-cols-2">
              {meta.sources.map((source, i) => <SourceCard key={i} source={source} />)}
            </div>
          </section>
        )}

        <div className="max-w-4xl mx-auto px-6 mt-12">
          <div className="flex items-start gap-3 rounded-xl bg-slate-50 p-5 border border-slate-100">
            <span className="material-symbols-outlined text-on-surface-variant text-lg mt-0.5">info</span>
            <div className="text-xs text-on-surface-variant leading-relaxed space-y-1">
              <p>{siteConfig.disclaimer}</p>
              {siteConfig.coupang.enabled && <p>{dict.coupang.disclaimer}</p>}
            </div>
          </div>
        </div>

        {meta.tags.length > 0 && (
          <div className="max-w-4xl mx-auto px-6 mt-10">
            <div className="flex flex-wrap gap-2">
              {meta.tags.map((tag) => (
                <a key={tag} href={lh(`/search?tag=${encodeURIComponent(tag)}`)} className="px-4 py-2 rounded-full bg-slate-50 border border-slate-100 text-sm text-on-surface-variant hover:border-primary hover:text-primary transition-all">#{tag}</a>
              ))}
            </div>
          </div>
        )}

        {siteConfig.coupang.enabled && (
          <div className="max-w-4xl mx-auto px-6 mt-10">
            <CoupangLinkAd keywords={["삼성 갤럭시북4 프로", "맥북 에어 M3", "로지텍 MX Master 3S", "LG 울트라와이드 모니터"]} title={dict.post.coupangDevTitle} />
          </div>
        )}

        {/* Prev / Next Navigation */}
        {(prevPost || nextPost) && (
          <nav className="max-w-4xl mx-auto px-6 mt-16">
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              {prevPost ? (
                <a href={lh(`/posts/${prevPost.slug}`)} className="group flex items-start gap-3 p-5 rounded-xl border border-slate-200 hover:border-primary/30 hover:bg-primary/[0.02] transition-all">
                  <span className="material-symbols-outlined text-slate-400 group-hover:text-primary mt-0.5">arrow_back</span>
                  <div className="min-w-0">
                    <p className="text-xs text-slate-400 mb-1">Previous</p>
                    <p className="text-sm font-semibold text-on-surface truncate group-hover:text-primary transition-colors">{prevPost.title}</p>
                  </div>
                </a>
              ) : <div />}
              {nextPost ? (
                <a href={lh(`/posts/${nextPost.slug}`)} className="group flex items-start gap-3 p-5 rounded-xl border border-slate-200 hover:border-primary/30 hover:bg-primary/[0.02] transition-all text-right sm:justify-end">
                  <div className="min-w-0">
                    <p className="text-xs text-slate-400 mb-1">Next</p>
                    <p className="text-sm font-semibold text-on-surface truncate group-hover:text-primary transition-colors">{nextPost.title}</p>
                  </div>
                  <span className="material-symbols-outlined text-slate-400 group-hover:text-primary mt-0.5">arrow_forward</span>
                </a>
              ) : <div />}
            </div>
          </nav>
        )}

        {related.length > 0 && (
          <section className="max-w-7xl mx-auto px-6 mt-20 pt-12 border-t border-slate-200/50">
            <div className="flex items-center justify-between mb-8">
              <h2 className="text-2xl font-extrabold text-on-surface font-headline">{dict.post.relatedPosts}</h2>
              <a href={lh("/posts")} className="text-sm text-primary font-bold hover:underline flex items-center gap-1">
                {dict.post.viewAll}
                <span className="material-symbols-outlined text-sm">arrow_forward</span>
              </a>
            </div>
            <div className="grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
              {related.map((p) => <PostCard key={p.slug} post={p} compact locale={locale} />)}
            </div>
          </section>
        )}
      </article>
    </>
  );
}
