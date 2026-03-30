import "./globals.css";

// 루트 레이아웃 — [locale]/layout.tsx가 실제 HTML 렌더링 담당
// Next.js가 루트 layout을 요구하므로 최소한으로 유지
export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return children;
}
