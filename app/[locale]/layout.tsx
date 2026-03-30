import { Metadata } from "next";
import Script from "next/script";
import { siteConfig } from "@/lib/config";
import {
  getDictionary,
  localizedHref,
  htmlLangs,
  ogLocales,
  locales,
  localeNames,
  defaultLocale,
  type Locale,
  type Dictionary,
} from "@/lib/i18n";
import { ScrollToTop } from "@/components/ScrollToTop";
import { MobileNav } from "@/components/MobileNav";

export async function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export async function generateMetadata({
  params,
}: {
  params: { locale: string };
}): Promise<Metadata> {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);

  return {
    metadataBase: new URL(siteConfig.url),
    title: {
      default: dict.meta.defaultTitle,
      template: `%s | ${siteConfig.name}`,
    },
    description: dict.meta.siteDescription,
    openGraph: {
      type: "website",
      locale: ogLocales[locale],
      url: siteConfig.url,
      siteName: siteConfig.name,
      title: dict.meta.defaultTitle,
      description: dict.meta.siteDescription,
    },
    twitter: { card: "summary_large_image" },
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
      canonical: `${siteConfig.url}${locale === defaultLocale ? "" : `/${locale}`}`,
      languages: {
        ko: siteConfig.url,
        en: `${siteConfig.url}/en`,
        zh: `${siteConfig.url}/zh`,
        ja: `${siteConfig.url}/ja`,
        es: `${siteConfig.url}/es`,
        "x-default": siteConfig.url,
      },
      types: {
        "application/rss+xml": `${siteConfig.url}/feed.xml`,
      },
    },
    verification: {
      google: "vlp5CU9LiT8K6iu4FQfca9Lkva_pUbd_xSkYeT60Hmc",
      other: {
        "naver-site-verification": "ccdc01cefc8b43cddda74be5174b84462ffe5e43",
      },
    },
  };
}

function JsonLd({ locale }: { locale: Locale }) {
  const lp = locale === defaultLocale ? "" : `/${locale}`;
  const schemas = [
    {
      "@context": "https://schema.org",
      "@type": "WebSite",
      name: siteConfig.name,
      url: siteConfig.url,
      description: siteConfig.description,
      inLanguage: htmlLangs[locale],
      potentialAction: {
        "@type": "SearchAction",
        target: `${siteConfig.url}${lp}/search?q={search_term_string}`,
        "query-input": "required name=search_term_string",
      },
    },
    {
      "@context": "https://schema.org",
      "@type": "Organization",
      name: siteConfig.name,
      url: siteConfig.url,
      logo: `${siteConfig.url}/favicon.svg`,
      description: siteConfig.description,
      sameAs: [
        siteConfig.social.instagram ? `https://www.instagram.com/${siteConfig.social.instagram}` : null,
        siteConfig.social.twitter ? `https://twitter.com/${siteConfig.social.twitter}` : null,
      ].filter(Boolean),
    },
  ];
  return (
    <>
      {schemas.map((schema, i) => (
        <script
          key={i}
          type="application/ld+json"
          dangerouslySetInnerHTML={{ __html: JSON.stringify(schema) }}
        />
      ))}
    </>
  );
}

// ── Nav key 매핑 ──
const navKeyMap: Record<string, string> = {
  "/": "home",
  "/categories/side-hustle": "sideHustle",
  "/categories/ai-tools": "aiTools",
  "/categories/ai-news": "aiNews",
  "/categories/marketing": "marketing",
  "/business": "agency",
  "/about": "about",
};

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: { locale: string };
}) {
  const locale = (params.locale || defaultLocale) as Locale;
  const dict = await getDictionary(locale);

  return (
    <html lang={htmlLangs[locale]} suppressHydrationWarning>
      <head>
        <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
        <link rel="manifest" href="/manifest.json" />
        <meta name="theme-color" content="#4F46E5" />
        <meta name="apple-mobile-web-app-capable" content="yes" />
        <meta name="apple-mobile-web-app-status-bar-style" content="default" />
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
        <JsonLd locale={locale} />
        {siteConfig.analytics.gaId && (
          <>
            <script
              async
              src={`https://www.googletagmanager.com/gtag/js?id=${siteConfig.analytics.gaId}`}
            />
            <script
              dangerouslySetInnerHTML={{
                __html: `window.dataLayer=window.dataLayer||[];function gtag(){dataLayer.push(arguments);}gtag('js',new Date());gtag('config','${siteConfig.analytics.gaId}');`,
              }}
            />
          </>
        )}
      </head>
      <body className="bg-background text-on-surface antialiased font-body">
        {process.env.NEXT_PUBLIC_ADSENSE_ID && (
          <Script
            src={`https://pagead2.googlesyndication.com/pagead/js/adsbygoogle.js?client=${process.env.NEXT_PUBLIC_ADSENSE_ID}`}
            strategy="afterInteractive"
            crossOrigin="anonymous"
          />
        )}
        {/* Header */}
        <header className="fixed top-0 w-full z-50 glass-header border-b border-slate-200/50 shadow-sm">
          <div className="flex justify-between items-center h-16 px-6 lg:px-12 max-w-7xl mx-auto">
            <a
              href={localizedHref("/", locale)}
              className="flex items-center gap-2.5 text-2xl font-black tracking-tight text-slate-900 font-headline"
            >
              <span className="inline-flex items-center justify-center w-8 h-8 rounded-lg bg-primary text-white text-sm font-bold">
                AI
              </span>
              <span>브리핑</span>
            </a>
            <nav className="hidden md:flex items-center space-x-8">
              {siteConfig.nav.map((item) => {
                const key = navKeyMap[item.href] || "home";
                return (
                  <a
                    key={item.href}
                    href={localizedHref(item.href, locale)}
                    className="text-slate-500 hover:text-primary transition-colors text-sm font-medium"
                  >
                    {(dict.nav as Record<string, string>)[key] || item.label}
                  </a>
                );
              })}
            </nav>
            <div className="flex items-center space-x-3">
              <a
                href={localizedHref("/search", locale)}
                className="p-2 text-slate-600 hover:text-primary transition-colors"
              >
                <span className="material-symbols-outlined">search</span>
              </a>
              <MobileNav
                items={siteConfig.nav.map((item) => {
                  const key = navKeyMap[item.href] || "home";
                  return {
                    href: localizedHref(item.href, locale),
                    label: (dict.nav as Record<string, string>)[key] || item.label,
                  };
                })}
                searchHref={localizedHref("/search", locale)}
              />
            </div>
          </div>
        </header>

        <main className="min-h-screen">{children}</main>

        <ScrollToTop />

        {/* Footer */}
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
                {dict.footer.sitemap}
              </a>
              <a className="text-slate-500 hover:text-primary transition-colors" href="/feed.xml">
                {dict.footer.rss}
              </a>
              <a className="underline text-slate-900 font-medium" href={localizedHref("/privacy", locale)}>
                {dict.footer.privacyPolicy}
              </a>
            </nav>
            <p className="text-xs text-slate-500 leading-relaxed max-w-2xl opacity-80">
              &copy; {new Date().getFullYear()} {siteConfig.name}. All rights reserved.
              <br />
              {siteConfig.disclaimer}
              {siteConfig.coupang.enabled && (
                <>
                  <br />
                  {dict.coupang.disclaimer}
                </>
              )}
            </p>
          </div>
        </footer>
      </body>
    </html>
  );
}
