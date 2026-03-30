import type { PostMeta } from "@/lib/posts";
import { getCategory } from "@/lib/config";
import { localizedHref, defaultLocale, type Locale } from "@/lib/i18n";

interface PostCardProps {
  post: PostMeta;
  compact?: boolean;
  featured?: boolean;
  locale?: Locale;
}

const difficultyColor: Record<string, string> = {
  beginner: "bg-emerald-100 text-emerald-700",
  intermediate: "bg-amber-100 text-amber-700",
  advanced: "bg-rose-100 text-rose-700",
};

const diffLabels: Record<Locale, Record<string, string>> = {
  ko: { beginner: "입문", intermediate: "중급", advanced: "심화" },
  en: { beginner: "Beginner", intermediate: "Intermediate", advanced: "Advanced" },
  zh: { beginner: "入门", intermediate: "中级", advanced: "高级" },
  ja: { beginner: "入門", intermediate: "中級", advanced: "上級" },
  es: { beginner: "Principiante", intermediate: "Intermedio", advanced: "Avanzado" },
};

export function PostCard({ post, compact, featured, locale = defaultLocale }: PostCardProps) {
  const category = getCategory(post.category);
  const lh = (path: string) => localizedHref(path, locale);
  const dl = diffLabels[locale] || diffLabels.ko;

  /* ── Featured: 풀 와이드 가로형 ── */
  if (featured) {
    return (
      <a
        href={lh(`/posts/${post.slug}`)}
        className="group block overflow-hidden rounded-2xl bg-white ring-1 ring-slate-200/60 hover:-translate-y-1 hover:shadow-[0_4px_12px_rgba(0,0,0,0.06),0_16px_40px_rgba(0,0,0,0.06)] transition-all duration-500"
      >
        <div className="flex flex-col md:flex-row">
          {/* 이미지 */}
          <div className="relative md:w-[45%] aspect-video md:aspect-auto overflow-hidden bg-slate-100">
            {post.thumbnail ? (
              <img
                src={post.thumbnail}
                alt={post.title}
                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 ease-out"
                loading="lazy"
              />
            ) : (
              <div className="w-full h-full min-h-[240px] bg-gradient-to-br from-indigo-100 to-violet-50 flex items-center justify-center">
                <span className="text-6xl opacity-20">{category?.emoji || "🤖"}</span>
              </div>
            )}
            <div className="absolute inset-0 bg-gradient-to-t from-black/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
            {category && (
              <span className="absolute top-4 left-4 px-3 py-1 rounded-full bg-white/90 backdrop-blur-sm text-xs font-bold text-primary shadow-sm">
                {category.emoji} {category.name}
              </span>
            )}
          </div>
          {/* 텍스트 */}
          <div className="flex-1 p-6 lg:p-8 flex flex-col justify-center">
            <div className="flex items-center gap-3 mb-3 text-xs text-slate-400">
              <time>{post.date}</time>
              {post.difficulty && (
                <>
                  <span className="w-1 h-1 bg-slate-300 rounded-full" />
                  <span className={`px-2 py-0.5 rounded-full font-medium ${difficultyColor[post.difficulty] || ""}`}>
                    {dl[post.difficulty] || post.difficulty}
                  </span>
                </>
              )}
            </div>
            <h3 className="text-xl lg:text-2xl font-bold text-on-surface group-hover:text-primary transition-colors duration-300 leading-snug font-headline mb-3 line-clamp-2">
              {post.title}
            </h3>
            <p className="text-sm text-on-surface-variant line-clamp-3 leading-relaxed">
              {post.description}
            </p>
            <span className="mt-5 inline-flex items-center gap-1.5 text-xs font-semibold text-primary opacity-0 group-hover:opacity-100 transition-opacity duration-300">
              자세히 읽기
              <span className="material-symbols-outlined text-xs group-hover:translate-x-0.5 transition-transform">arrow_forward</span>
            </span>
          </div>
        </div>
      </a>
    );
  }

  /* ── Compact: 사이드바/리스트용 ── */
  if (compact) {
    return (
      <a href={lh(`/posts/${post.slug}`)} className="group flex items-center gap-4 p-3 rounded-xl hover:bg-slate-50 transition-colors duration-300">
        {post.thumbnail ? (
          <div className="w-16 h-16 rounded-xl overflow-hidden flex-shrink-0 bg-slate-100">
            <img src={post.thumbnail} alt={post.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" loading="lazy" />
          </div>
        ) : (
          <div className="w-16 h-16 rounded-xl flex-shrink-0 bg-gradient-to-br from-indigo-50 to-violet-50 flex items-center justify-center">
            <span className="text-xl opacity-30">{category?.emoji || "🤖"}</span>
          </div>
        )}
        <div className="flex-1 min-w-0">
          <h3 className="text-sm font-bold text-on-surface group-hover:text-primary transition-colors line-clamp-2 leading-snug">{post.title}</h3>
          <time className="mt-1 block text-xs text-slate-400">{post.date}</time>
        </div>
      </a>
    );
  }

  /* ── Standard: 기본 카드 ── */
  return (
    <a
      href={lh(`/posts/${post.slug}`)}
      className="group block overflow-hidden rounded-2xl bg-white ring-1 ring-slate-200/60 hover:-translate-y-1 hover:shadow-[0_4px_12px_rgba(0,0,0,0.06),0_16px_40px_rgba(0,0,0,0.06)] transition-all duration-500"
    >
      {post.thumbnail ? (
        <div className="relative aspect-video overflow-hidden bg-slate-100">
          <img src={post.thumbnail} alt={post.title} className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-700 ease-out" loading="lazy" />
          <div className="absolute inset-0 bg-gradient-to-t from-black/10 to-transparent opacity-0 group-hover:opacity-100 transition-opacity duration-500" />
          {category && (
            <span className="absolute top-3 left-3 px-2.5 py-0.5 rounded-full bg-white/90 backdrop-blur-sm text-[11px] font-bold text-primary shadow-sm">
              {category.emoji} {category.name}
            </span>
          )}
        </div>
      ) : (
        <div className="relative aspect-video bg-gradient-to-br from-indigo-50 via-white to-violet-50 flex items-center justify-center">
          <span className="text-5xl opacity-15">{category?.emoji || "🤖"}</span>
          {category && (
            <span className="absolute top-3 left-3 px-2.5 py-0.5 rounded-full bg-white/80 text-[11px] font-bold text-primary">
              {category.emoji} {category.name}
            </span>
          )}
        </div>
      )}
      <div className="p-5 lg:p-6">
        <div className="flex items-center gap-2 mb-2.5">
          {post.difficulty && (
            <span className={`px-2 py-0.5 rounded-full text-[10px] font-semibold ${difficultyColor[post.difficulty] || ""}`}>
              {dl[post.difficulty] || post.difficulty}
            </span>
          )}
          <time className="text-xs text-slate-400 ml-auto">{post.date}</time>
        </div>
        <h3 className="text-base lg:text-lg font-bold text-on-surface group-hover:text-primary transition-colors duration-300 line-clamp-2 leading-snug font-headline mb-2">
          {post.title}
        </h3>
        <p className="text-sm text-on-surface-variant line-clamp-2 leading-relaxed">{post.description}</p>
      </div>
    </a>
  );
}
