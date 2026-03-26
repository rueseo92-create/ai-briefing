import type { SourceLink } from "@/lib/posts";

interface SourceCardProps {
  source: SourceLink;
}

const typeIcon: Record<string, string> = {
  government: "account_balance",
  paper: "description",
  news: "newspaper",
  official: "verified",
};

const typeLabel: Record<string, string> = {
  government: "정부 공고",
  paper: "논문/보고서",
  news: "뉴스",
  official: "공식 문서",
};

export function SourceCard({ source }: SourceCardProps) {
  const icon = typeIcon[source.type || ""] || "link";
  const label = typeLabel[source.type || ""] || "출처";

  return (
    <a
      href={source.url}
      target="_blank"
      rel="noopener noreferrer"
      className="group flex items-center gap-4 p-4 rounded-xl bg-white border border-slate-200/80 hover:border-primary/30 hover:shadow-md transition-all"
    >
      <div className="flex-shrink-0 w-10 h-10 rounded-lg bg-primary/10 flex items-center justify-center">
        <span className="material-symbols-outlined text-primary text-xl">{icon}</span>
      </div>
      <div className="flex-1 min-w-0">
        <p className="text-sm font-semibold text-on-surface group-hover:text-primary transition-colors truncate">
          {source.name}
        </p>
        <p className="text-xs text-on-surface-variant mt-0.5">{label}</p>
      </div>
      <span className="material-symbols-outlined text-slate-400 group-hover:text-primary transition-colors text-lg">
        open_in_new
      </span>
    </a>
  );
}
