/**
 * /api/og - 동적 Open Graph 이미지 생성
 *
 * 사용: <meta property="og:image" content="/api/og?title=제목&category=AI뉴스" />
 */
import { ImageResponse } from "next/og";
import { NextRequest } from "next/server";
import { siteConfig } from "@/lib/config";

export const runtime = "edge";

const categoryColors: Record<string, string> = {
  "ai-news": "#6366F1",
  "gov-projects": "#059669",
  "ai-tools": "#0891B2",
  tutorials: "#7C3AED",
  marketing: "#D97706",
};

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const title = searchParams.get("title") || siteConfig.defaultTitle;
  const category = searchParams.get("category") || "";
  const accent = categoryColors[category] || "#6366F1";

  return new ImageResponse(
    (
      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "space-between",
          padding: "60px 72px",
          background: "linear-gradient(145deg, #0F0B2E 0%, #1a1145 40%, #0c1a3a 100%)",
          fontFamily: "sans-serif",
        }}
      >
        {/* 상단: 카테고리 + 장식 */}
        <div style={{ display: "flex", alignItems: "center", gap: 16 }}>
          {category && (
            <span
              style={{
                fontSize: 16,
                fontWeight: 700,
                color: accent,
                background: `${accent}18`,
                padding: "8px 20px",
                borderRadius: 40,
                border: `1px solid ${accent}40`,
                letterSpacing: "0.05em",
                textTransform: "uppercase",
              }}
            >
              {category}
            </span>
          )}
        </div>

        {/* 중앙: 제목 */}
        <div
          style={{
            fontSize: 56,
            fontWeight: 800,
            color: "#ffffff",
            lineHeight: 1.2,
            letterSpacing: "-0.02em",
            display: "-webkit-box",
            WebkitLineClamp: 3,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
            maxWidth: "90%",
          }}
        >
          {title}
        </div>

        {/* 하단: 브랜드 */}
        <div style={{ display: "flex", alignItems: "center", gap: 14 }}>
          <div
            style={{
              width: 40,
              height: 40,
              borderRadius: 10,
              background: "linear-gradient(135deg, #4F46E5, #7C3AED)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 16,
              fontWeight: 800,
              color: "white",
            }}
          >
            AI
          </div>
          <span style={{ fontSize: 20, fontWeight: 700, color: "rgba(255,255,255,0.5)" }}>
            {siteConfig.name}
          </span>
          <div style={{ flex: 1 }} />
          <span style={{ fontSize: 14, color: "rgba(255,255,255,0.2)" }}>
            seroai.xyz
          </span>
        </div>

        {/* 장식 글로우 */}
        <div
          style={{
            position: "absolute",
            top: 0,
            right: 0,
            width: "50%",
            height: "100%",
            background: `radial-gradient(ellipse at 80% 30%, ${accent}15, transparent 60%)`,
          }}
        />
      </div>
    ),
    { width: 1200, height: 630 }
  );
}
