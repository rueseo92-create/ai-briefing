import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";
import { PostCard } from "@/components/PostCard";
import { getDictionary, localizedHref, defaultLocale, type Locale } from "@/lib/i18n";

export default async function PostsPage({ params }: { params: { locale: string } }) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);
  const lh = (path: string) => localizedHref(path, locale);
  const posts = getAllPosts(locale as "ko" | "en");

  return (
    <div className="pt-28 pb-20 max-w-7xl mx-auto px-6 lg:px-12">
      <header className="mb-12">
        <h1 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline">{dict.category.allPosts}</h1>
        <p className="mt-2 text-on-surface-variant">{dict.category.postsCount.replace("{n}", String(posts.length))}</p>
      </header>

      <section className="mb-12">
        <div className="flex items-center gap-3 overflow-x-auto pb-4 no-scrollbar">
          <a href={lh("/posts")} className="px-6 py-2.5 rounded-full bg-primary text-on-primary font-bold text-sm shadow-md shadow-primary/20 whitespace-nowrap">{dict.category.all}</a>
          {siteConfig.categories.map((cat) => (
            <a key={cat.slug} href={lh(`/categories/${cat.slug}`)} className="px-6 py-2.5 rounded-full bg-surface-container-low text-on-surface-variant hover:bg-surface-container-high transition-colors font-medium text-sm whitespace-nowrap">
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
          <p className="text-6xl mb-4">📝</p>
          <h2 className="text-xl font-bold text-on-surface mb-2 font-headline">{dict.home.noPosts}</h2>
        </div>
      )}
    </div>
  );
}
