import { Metadata } from "next";
import { getAllPosts } from "@/lib/posts";
import { siteConfig } from "@/lib/config";
import { PostCard } from "@/components/PostCard";

export const metadata: Metadata = {
  title: "전체 글",
  description: `${siteConfig.name}의 모든 글 모아보기`,
};

export default function PostsPage() {
  const posts = getAllPosts();

  return (
    <div className="pt-28 pb-20 max-w-7xl mx-auto px-6 lg:px-12">
      {/* Header */}
      <header className="mb-12">
        <h1 className="text-3xl lg:text-4xl font-extrabold text-on-surface font-headline">
          전체 글
        </h1>
        <p className="mt-2 text-on-surface-variant">
          총 {posts.length}개의 글
        </p>
      </header>

      {/* Category Filter */}
      <section className="mb-12">
        <div className="flex items-center gap-3 overflow-x-auto pb-4 no-scrollbar">
          <a
            href="/posts"
            className="px-6 py-2.5 rounded-full bg-primary text-on-primary font-bold text-sm shadow-md shadow-primary/20 whitespace-nowrap"
          >
            전체
          </a>
          {siteConfig.categories.map((cat) => (
            <a
              key={cat.slug}
              href={`/categories/${cat.slug}`}
              className="px-6 py-2.5 rounded-full bg-surface-container-low text-on-surface-variant hover:bg-surface-container-high transition-colors font-medium text-sm whitespace-nowrap"
            >
              {cat.emoji} {cat.name}
            </a>
          ))}
        </div>
      </section>

      {/* Posts Grid */}
      {posts.length > 0 ? (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
          {posts.map((post) => (
            <PostCard key={post.slug} post={post} />
          ))}
        </div>
      ) : (
        <div className="py-20 text-center">
          <p className="text-6xl mb-4">📝</p>
          <h2 className="text-xl font-bold text-on-surface mb-2 font-headline">
            아직 글이 없습니다
          </h2>
          <p className="text-on-surface-variant text-sm">
            content/posts/ 에 .mdx 파일을 추가해보세요
          </p>
        </div>
      )}
    </div>
  );
}
