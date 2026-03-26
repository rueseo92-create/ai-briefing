import type { CoupangProduct } from "@/lib/posts";

interface Props {
  product: CoupangProduct;
}

function StarRating({ rating }: { rating: number }) {
  const stars = [];
  for (let i = 1; i <= 5; i++) {
    if (i <= Math.floor(rating)) {
      stars.push(
        <span key={i} className="material-symbols-outlined text-amber-500 text-base" style={{ fontVariationSettings: "'FILL' 1" }}>
          star
        </span>
      );
    } else if (i - rating < 1) {
      stars.push(
        <span key={i} className="material-symbols-outlined text-amber-500 text-base" style={{ fontVariationSettings: "'FILL' 1" }}>
          star_half
        </span>
      );
    } else {
      stars.push(
        <span key={i} className="material-symbols-outlined text-stone-300 text-base">
          star
        </span>
      );
    }
  }
  return <div className="flex items-center gap-0.5">{stars}</div>;
}

export function CoupangProductCard({ product }: Props) {
  return (
    <div className="rounded-2xl border border-outline-variant/15 bg-surface-container-lowest overflow-hidden shadow-sm hover:shadow-lg transition-shadow">
      {/* Product Image */}
      {product.image && (
        <div className="aspect-[16/10] overflow-hidden bg-surface-container">
          <img
            src={product.image}
            alt={product.name}
            className="w-full h-full object-cover"
            loading="lazy"
          />
        </div>
      )}

      <div className="p-6">
        {/* Product Name */}
        <h3 className="text-lg font-extrabold text-on-surface mb-2 leading-snug font-headline">
          {product.name}
        </h3>

        {/* Rating + Price Row */}
        <div className="flex items-center justify-between mb-5">
          {product.rating && (
            <div className="flex items-center gap-2">
              <StarRating rating={product.rating} />
              <span className="text-sm font-bold text-on-surface-variant">
                {product.rating.toFixed(1)}
              </span>
            </div>
          )}
          {product.price && (
            <p className="text-xl font-extrabold text-primary">
              {product.price.toLocaleString("ko-KR")}
              <span className="text-sm font-medium ml-0.5">원</span>
            </p>
          )}
        </div>

        {/* Pros & Cons Grid */}
        {(product.pros?.length || product.cons?.length) && (
          <div className="grid grid-cols-2 gap-3 mb-6">
            {/* Pros */}
            {product.pros && product.pros.length > 0 && (
              <div className="space-y-2">
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-tertiary/10 text-tertiary text-xs font-bold uppercase tracking-wider">
                  <span className="material-symbols-outlined text-sm">thumb_up</span>
                  장점
                </span>
                {product.pros.map((pro, i) => (
                  <p key={i} className="text-sm text-on-surface-variant leading-relaxed pl-1">
                    {pro}
                  </p>
                ))}
              </div>
            )}

            {/* Cons */}
            {product.cons && product.cons.length > 0 && (
              <div className="space-y-2">
                <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded bg-error/10 text-error text-xs font-bold uppercase tracking-wider">
                  <span className="material-symbols-outlined text-sm">thumb_down</span>
                  단점
                </span>
                {product.cons.map((con, i) => (
                  <p key={i} className="text-sm text-on-surface-variant leading-relaxed pl-1">
                    {con}
                  </p>
                ))}
              </div>
            )}
          </div>
        )}

        {/* CTA Button */}
        <a
          href={product.link}
          target="_blank"
          rel="noopener noreferrer nofollow"
          className="flex items-center justify-center gap-2 w-full py-3.5 bg-gradient-to-r from-primary to-primary-container text-on-primary font-bold rounded-xl hover:shadow-lg hover:shadow-primary/25 transition-all text-sm"
        >
          <span className="material-symbols-outlined text-lg">shopping_bag</span>
          쿠팡에서 확인하기
          <span className="material-symbols-outlined text-sm">arrow_forward</span>
        </a>
      </div>
    </div>
  );
}
