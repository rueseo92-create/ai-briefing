import { notFound } from "next/navigation";
import { Metadata } from "next";
import { getPostsByCategory } from "@/lib/posts";
import { siteConfig, getCategory } from "@/lib/config";
import { PostCard } from "@/components/PostCard";
import { getDictionary, localizedHref, locales, defaultLocale, type Locale } from "@/lib/i18n";

export function generateStaticParams() {
  return locales.flatMap((locale) =>
    siteConfig.categories.map((cat) => ({ locale, slug: cat.slug }))
  );
}

export function generateMetadata({ params }: { params: { slug: string } }): Metadata {
  const category = getCategory(params.slug);
  if (!category) return {};
  return {
    title: `${category.emoji} ${category.name}`,
    description: `${siteConfig.name} — ${category.name}`,
  };
}

export default async function CategoryPage({ params }: { params: { locale: string; slug: string } }) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);
  const lh = (path: string) => localizedHref(path, locale);

  const category = getCategory(params.slug);
  if (!category) notFound();

  const posts = getPostsByCategory(params.slug);

  return (
    <div className="pt-28 pb-20 max-w-7xl mx-auto px-6 lg:px-12" data-category={params.slug}>
      <header className="mb-12">
        <div className="flex items-center gap-3 mb-2">
          <a href={lh("/")} className="text-on-surface-variant hover:text-primary transition-colors text-sm">
            <span className="material-symbols-outlined text-base align-middle">home</span>
          </a>
          <span className="material-symbols-outlined text-xs text-stone-300">chevron_right</span>
          <span className="text-sm text-on-surface font-medium">{category.name}</span>
        </div>
        <h1 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline">{category.emoji} {category.name}</h1>
        <p className="mt-2 text-on-surface-variant">{dict.category.postsCount.replace("{n}", String(posts.length))}</p>
      </header>

      <section className="mb-12">
        <div className="flex items-center gap-3 overflow-x-auto pb-4 no-scrollbar">
          <a href={lh("/")} className="px-6 py-2.5 rounded-full bg-surface-container-low text-on-surface-variant hover:bg-surface-container-high transition-colors font-medium text-sm whitespace-nowrap">{dict.category.all}</a>
          {siteConfig.categories.map((cat) => (
            <a key={cat.slug} href={lh(`/categories/${cat.slug}`)} className={cat.slug === params.slug ? "px-6 py-2.5 rounded-full bg-primary text-on-primary font-bold text-sm shadow-md shadow-primary/20 whitespace-nowrap" : "px-6 py-2.5 rounded-full bg-surface-container-low text-on-surface-variant hover:bg-surface-container-high transition-colors font-medium text-sm whitespace-nowrap"}>
              {cat.emoji} {cat.name}
            </a>
          ))}
        </div>
      </section>

      {posts.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {posts.map((post) => <PostCard key={post.slug} post={post} locale={locale} />)}
        </div>
      ) : (
        <div className="py-20 text-center">
          <p className="text-5xl mb-4">{category.emoji}</p>
          <h2 className="text-xl font-bold text-on-surface mb-2 font-headline">{dict.category.noPosts.replace("{name}", category.name)}</h2>
          <p className="text-on-surface-variant text-sm">{dict.category.noPostsDesc}</p>
        </div>
      )}
    </div>
  );
}
