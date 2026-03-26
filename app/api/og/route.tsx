/**
 * /api/og - 동적 Open Graph 이미지 생성
 *
 * 사용: <meta property="og:image" content="/api/og?title=제목&category=리뷰" />
 * SNS 공유 시 자동으로 예쁜 카드 이미지 생성
 */
import { ImageResponse } from "next/og";
import { NextRequest } from "next/server";
import { siteConfig } from "@/lib/config";

export const runtime = "edge";

export async function GET(req: NextRequest) {
  const { searchParams } = new URL(req.url);
  const title = searchParams.get("title") || siteConfig.defaultTitle;
  const category = searchParams.get("category") || "";

  return new ImageResponse(
    (
      <div
        style={{
          height: "100%",
          width: "100%",
          display: "flex",
          flexDirection: "column",
          justifyContent: "center",
          padding: "60px 80px",
          background: "linear-gradient(135deg, #1a1a2e 0%, #16213e 50%, #0f3460 100%)",
          fontFamily: "sans-serif",
        }}
      >
        {/* Category badge */}
        {category && (
          <div
            style={{
              display: "flex",
              alignItems: "center",
              marginBottom: 20,
            }}
          >
            <span
              style={{
                fontSize: 18,
                color: "#ff8c00",
                background: "rgba(255,140,0,0.15)",
                padding: "6px 16px",
                borderRadius: 20,
                border: "1px solid rgba(255,140,0,0.3)",
              }}
            >
              {category}
            </span>
          </div>
        )}

        {/* Title */}
        <div
          style={{
            fontSize: 48,
            fontWeight: 800,
            color: "#ffffff",
            lineHeight: 1.3,
            marginBottom: 30,
            display: "-webkit-box",
            WebkitLineClamp: 3,
            WebkitBoxOrient: "vertical",
            overflow: "hidden",
          }}
        >
          {title}
        </div>

        {/* Site name */}
        <div
          style={{
            display: "flex",
            alignItems: "center",
            gap: 12,
          }}
        >
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: 8,
              background: "linear-gradient(135deg, #ff8c00, #e65100)",
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              fontSize: 18,
              color: "white",
            }}
          >
            📝
          </div>
          <span style={{ fontSize: 22, color: "#8899aa" }}>
            {siteConfig.name}
          </span>
        </div>
      </div>
    ),
    {
      width: 1200,
      height: 630,
    }
  );
}
