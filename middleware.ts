import { NextRequest, NextResponse } from "next/server";

const locales = ["ko", "en"];
const defaultLocale = "ko";

// 정적 파일 및 API 경로 패턴
const SKIP_PREFIXES = ["/_next", "/api", "/favicon.ico"];
const STATIC_EXT = /\.(ico|png|jpg|jpeg|gif|svg|webp|css|js|xml|txt|json|woff|woff2|ttf|eot)$/;

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl;

  // 정적 파일/API 스킵
  if (SKIP_PREFIXES.some((p) => pathname.startsWith(p)) || STATIC_EXT.test(pathname)) {
    return NextResponse.next();
  }

  // URL에서 로케일 추출
  const segments = pathname.split("/");
  const firstSegment = segments[1];

  // 이미 로케일 prefix가 있으면 그대로 통과
  if (locales.includes(firstSegment) && firstSegment !== defaultLocale) {
    return NextResponse.next();
  }

  // /ko/... 는 / 로 리다이렉트 (기본 언어는 prefix 없음)
  if (firstSegment === defaultLocale) {
    const newPath = "/" + segments.slice(2).join("/");
    return NextResponse.redirect(new URL(newPath || "/", request.url), 301);
  }

  // 로케일 없는 경로 → /ko/ 로 내부 리라이트 (URL 변경 없음)
  const url = request.nextUrl.clone();
  url.pathname = `/${defaultLocale}${pathname}`;
  return NextResponse.rewrite(url);
}

export const config = {
  matcher: ["/((?!_next|api|favicon\\.ico|.*\\..*).*)"],
};
