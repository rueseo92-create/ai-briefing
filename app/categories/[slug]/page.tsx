import { notFound } from "next/navigation";
import { Metadata } from "next";
import { getPostsByCategory } from "@/lib/posts";
import { siteConfig, getCategory } from "@/lib/config";
import { PostCard } from "@/components/PostCard";

export function generateStaticParams() {
  return siteConfig.categories.map((cat) => ({ slug: cat.slug }));
}

export function generateMetadata({ params }: { params: { slug: string } }): Metadata {
  const category = getCategory(params.slug);
  if (!category) return {};

  return {
    title: `${category.emoji} ${category.name}`,
    description: `${siteConfig.name}의 ${category.name} 카테고리 글 모음`,
  };
}

export default function CategoryPage({ params }: { params: { slug: string } }) {
  const category = getCategory(params.slug);
  if (!category) notFound();

  const posts = getPostsByCategory(params.slug);

  return (
    <div className="pt-28 pb-20 max-w-7xl mx-auto px-6 lg:px-12">
      {/* Header */}
      <header className="mb-12">
        <div className="flex items-center gap-3 mb-2">
          <a href="/" className="text-on-surface-variant hover:text-primary transition-colors text-sm">
            <span className="material-symbols-outlined text-base align-middle">home</span>
          </a>
          <span className="material-symbols-outlined text-xs text-stone-300">chevron_right</span>
          <span className="text-sm text-on-surface font-medium">{category.name}</span>
        </div>
        <h1 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline">
          {category.emoji} {category.name}
        </h1>
        <p className="mt-2 text-on-surface-variant">
          {posts.length}개의 글
        </p>
      </header>

      {/* Category Filter Bar */}
      <section className="mb-12">
        <div className="flex items-center gap-3 overflow-x-auto pb-4 no-scrollbar">
          <a
            href="/"
            className="px-6 py-2.5 rounded-full bg-surface-container-low text-on-surface-variant hover:bg-surface-container-high transition-colors font-medium text-sm whitespace-nowrap"
          >
            전체
          </a>
          {siteConfig.categories.map((cat) => (
            <a
              key={cat.slug}
              href={`/categories/${cat.slug}`}
              className={
                cat.slug === params.slug
                  ? "px-6 py-2.5 rounded-full bg-primary text-on-primary font-bold text-sm shadow-md shadow-primary/20 whitespace-nowrap"
                  : "px-6 py-2.5 rounded-full bg-surface-container-low text-on-surface-variant hover:bg-surface-container-high transition-colors font-medium text-sm whitespace-nowrap"
              }
            >
              {cat.emoji} {cat.name}
            </a>
          ))}
        </div>
      </section>

      {/* Posts */}
      {posts.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {posts.map((post) => (
            <PostCard key={post.slug} post={post} />
          ))}
        </div>
      ) : (
        <div className="py-20 text-center">
          <p className="text-5xl mb-4">{category.emoji}</p>
          <h2 className="text-xl font-bold text-on-surface mb-2 font-headline">
            아직 {category.name} 글이 없습니다
          </h2>
          <p className="text-on-surface-variant text-sm">
            곧 새로운 글이 올라올 예정입니다.
          </p>
        </div>
      )}
    </div>
  );
}
