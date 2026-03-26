import type { PostMeta } from "@/lib/posts";
import { getCategory } from "@/lib/config";

interface PostCardProps {
  post: PostMeta;
  compact?: boolean;
}

const difficultyLabel: Record<string, string> = {
  beginner: "입문",
  intermediate: "중급",
  advanced: "심화",
};

const difficultyColor: Record<string, string> = {
  beginner: "bg-emerald-100 text-emerald-700",
  intermediate: "bg-amber-100 text-amber-700",
  advanced: "bg-rose-100 text-rose-700",
};

export function PostCard({ post, compact }: PostCardProps) {
  const category = getCategory(post.category);

  if (compact) {
    return (
      <a
        href={`/posts/${post.slug}`}
        className="group block overflow-hidden rounded-xl bg-white border border-slate-200/80 hover:shadow-lg hover:shadow-primary/5 transition-all"
      >
        {post.thumbnail && (
          <div className="aspect-video overflow-hidden">
            <img
              src={post.thumbnail}
              alt={post.title}
              className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
              loading="lazy"
            />
          </div>
        )}
        <div className="p-4">
          <h3 className="text-sm font-bold text-on-surface group-hover:text-primary transition-colors line-clamp-2 font-headline">
            {post.title}
          </h3>
          <time className="mt-1 block text-xs text-on-surface-variant">{post.date}</time>
        </div>
      </a>
    );
  }

  return (
    <a
      href={`/posts/${post.slug}`}
      className="group block overflow-hidden rounded-xl bg-white border border-slate-200/80 hover:shadow-xl hover:shadow-primary/5 hover:border-primary/20 transition-all duration-300"
    >
      {/* Thumbnail */}
      {post.thumbnail ? (
        <div className="aspect-video overflow-hidden bg-slate-100">
          <img
            src={post.thumbnail}
            alt={post.title}
            className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500"
            loading="lazy"
          />
        </div>
      ) : (
        <div className="aspect-video bg-gradient-to-br from-indigo-50 to-cyan-50 flex items-center justify-center">
          <span className="text-4xl opacity-40">
            {category?.emoji || "🤖"}
          </span>
        </div>
      )}

      {/* Content */}
      <div className="p-6">
        {/* Category + Date + Difficulty */}
        <div className="mb-3 flex items-center gap-2 flex-wrap">
          {category && (
            <span className="inline-flex items-center px-2.5 py-0.5 rounded-full bg-primary/10 text-primary text-xs font-bold">
              {category.emoji} {category.name}
            </span>
          )}
          {post.difficulty && (
            <span className={`px-2 py-0.5 rounded-full text-xs font-medium ${difficultyColor[post.difficulty] || ""}`}>
              {difficultyLabel[post.difficulty] || post.difficulty}
            </span>
          )}
          <time className="text-xs text-on-surface-variant tracking-wide ml-auto">
            {post.date}
          </time>
        </div>

        {/* Title */}
        <h3 className="mb-2 text-lg font-extrabold text-on-surface group-hover:text-primary transition-colors line-clamp-2 leading-snug font-headline">
          {post.title}
        </h3>

        {/* Description */}
        <p className="text-sm text-on-surface-variant line-clamp-2 leading-relaxed">
          {post.description}
        </p>

        {/* Tags */}
        {post.tags.length > 0 && (
          <div className="mt-4 flex flex-wrap gap-1.5">
            {post.tags.slice(0, 3).map((tag) => (
              <span
                key={tag}
                className="px-2.5 py-1 bg-slate-50 border border-slate-100 rounded-md text-xs text-on-surface-variant"
              >
                #{tag}
              </span>
            ))}
          </div>
        )}
      </div>
    </a>
  );
}
