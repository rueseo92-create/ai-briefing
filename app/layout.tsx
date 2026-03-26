import type { Metadata } from "next";
import { siteConfig } from "@/lib/config";
import "./globals.css";

export const metadata: Metadata = {
  metadataBase: new URL(siteConfig.url),
  title: {
    default: siteConfig.defaultTitle,
    template: siteConfig.titleTemplate,
  },
  description: siteConfig.description,
  openGraph: {
    type: "website",
    locale: siteConfig.locale,
    url: siteConfig.url,
    siteName: siteConfig.name,
    title: siteConfig.defaultTitle,
    description: siteConfig.description,
  },
  twitter: {
    card: "summary_large_image",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  alternates: {
    canonical: siteConfig.url,
    types: {
      "application/rss+xml": `${siteConfig.url}/feed.xml`,
    },
  },
  verification: {
    google: "vlp5CU9LiT8K6iu4FQfca9Lkva_pUbd_xSkYeT60Hmc",
  },
};

function JsonLd() {
  const schema = {
    "@context": "https://schema.org",
    "@type": "WebSite",
    name: siteConfig.name,
    url: siteConfig.url,
    description: siteConfig.description,
    potentialAction: {
      "@type": "SearchAction",
      target: `${siteConfig.url}/search?q={search_term_string}`,
      "query-input": "required name=search_term_string",
    },
  };

  return (
    <script
      type="application/ld+json"
      dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
    />
  );
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ko">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Manrope:wght@700;800&family=Inter:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap"
          rel="stylesheet"
        />
        <link
          href="https://fonts.googleapis.com/css2?family=Material+Symbols+Outlined:wght,FILL@100..700,0..1&display=swap"
          rel="stylesheet"
        />
        <JsonLd />
        {siteConfig.analytics.gaId && (
          <>
            <script
              async
              src={`https://www.googletagmanager.com/gtag/js?id=${siteConfig.analytics.gaId}`}
            />
            <script
              dangerouslySetInnerHTML={{
                __html: `
                  window.dataLayer = window.dataLayer || [];
                  function gtag(){dataLayer.push(arguments);}
                  gtag('js', new Date());
                  gtag('config', '${siteConfig.analytics.gaId}');
                `,
              }}
            />
          </>
        )}
      </head>
      <body className="bg-background text-on-surface antialiased font-body">
        <Header />
        <main className="min-h-screen">{children}</main>
        <Footer />
      </body>
    </html>
  );
}

function Header() {
  return (
    <header className="fixed top-0 w-full z-50 glass-header border-b border-slate-200/50 shadow-sm">
      <div className="flex justify-between items-center h-16 px-6 lg:px-12 max-w-7xl mx-auto">
        <a href="/" className="flex items-center gap-2.5 text-2xl font-black tracking-tight text-slate-900 font-headline">
          <span className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-primary text-white text-sm font-bold">
            AI
          </span>
          <span>브리핑</span>
        </a>
        <nav className="hidden md:flex items-center space-x-8">
          {siteConfig.nav.map((item) => (
            <a
              key={item.href}
              href={item.href}
              className="text-slate-500 hover:text-primary transition-colors text-sm font-medium"
            >
              {item.label}
            </a>
          ))}
        </nav>
        <div className="flex items-center space-x-4">
          <button className="p-2 text-slate-600 hover:text-primary transition-colors">
            <span className="material-symbols-outlined">search</span>
          </button>
          <button className="p-2 text-slate-600 hover:text-primary transition-colors md:hidden">
            <span className="material-symbols-outlined">menu</span>
          </button>
        </div>
      </div>
    </header>
  );
}

function Footer() {
  return (
    <footer className="w-full py-12 mt-20 bg-slate-50 border-t border-slate-200">
      <div className="flex flex-col items-center text-center px-4 max-w-4xl mx-auto space-y-6">
        <div className="flex items-center gap-2 text-lg font-bold text-slate-400 font-headline">
          <span className="inline-flex items-center justify-center w-6 h-6 rounded bg-slate-300 text-white text-xs font-bold">
            AI
          </span>
          브리핑
        </div>
        <nav className="flex gap-6 text-xs">
          <a className="text-slate-500 hover:text-primary transition-colors" href="/sitemap.xml">
            사이트맵
          </a>
          <a className="text-slate-500 hover:text-primary transition-colors" href="/feed.xml">
            RSS
          </a>
          <a className="underline text-slate-900 font-medium" href="/privacy">
            개인정보처리방침
          </a>
        </nav>
        <p className="text-xs text-slate-500 leading-relaxed max-w-2xl opacity-80">
          &copy; {new Date().getFullYear()} {siteConfig.name}. All rights reserved.
          <br />
          {siteConfig.disclaimer}
          {siteConfig.coupang.enabled && (
            <>
              <br />
              {siteConfig.coupang.disclaimer}
            </>
          )}
        </p>
      </div>
    </footer>
  );
}
