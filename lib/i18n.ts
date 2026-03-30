export const locales = ["ko", "en"] as const;
export type Locale = (typeof locales)[number];
export const defaultLocale: Locale = "ko";

export const localeNames: Record<Locale, string> = {
  ko: "한국어",
  en: "English",
};

export const ogLocales: Record<Locale, string> = {
  ko: "ko_KR",
  en: "en_US",
};

export const htmlLangs: Record<Locale, string> = {
  ko: "ko",
  en: "en",
};

// Dictionary 타입
export interface Dictionary {
  meta: { siteDescription: string; defaultTitle: string };
  nav: Record<string, string>;
  home: {
    latest: string;
    all: string;
    viewAllPosts: string;
    noPosts: string;
    noPostsDesc: string;
    firstPostSoon: string;
    popularKeywords: string;
    newsletter: string;
    newsletterDesc: string;
    emailPlaceholder: string;
    subscribe: string;
    noSpam: string;
    aboutThisBlog: string;
    aboutItems: string[];
    coupangTitle: string;
    coupangDevTitle: string;
  };
  post: {
    readingTime: string;
    references: string;
    relatedPosts: string;
    viewAll: string;
    beginner: string;
    intermediate: string;
    advanced: string;
    home: string;
    coupangReaderTitle: string;
    coupangDevTitle: string;
    koreanContentNotice: string;
  };
  search: {
    title: string;
    description: string;
    placeholder: string;
    button: string;
    popularKeywords: string;
    results: string;
    noResults: string;
    noResultsDesc: string;
    initialTitle: string;
    initialDesc: string;
    reset: string;
    tag: string;
  };
  category: {
    postsCount: string;
    all: string;
    noPosts: string;
    noPostsDesc: string;
    allPosts: string;
  };
  footer: {
    sitemap: string;
    rss: string;
    privacyPolicy: string;
  };
  coupang: {
    viewOnCoupang: string;
    recommendation: string;
    disclaimer: string;
    sponsored: string;
  };
}

// 사전 로딩 (빌드 타임에 JSON import)
const dictionaries: Record<Locale, () => Promise<Dictionary>> = {
  ko: () => import("@/dictionaries/ko.json").then((m) => m.default),
  en: () => import("@/dictionaries/en.json").then((m) => m.default),
};

export async function getDictionary(locale: Locale): Promise<Dictionary> {
  return dictionaries[locale]();
}

// 로케일 기반 href 생성
export function localizedHref(path: string, locale: Locale): string {
  if (locale === defaultLocale) return path;
  return `/${locale}${path}`;
}

// 유효한 로케일인지 확인
export function isValidLocale(value: string): value is Locale {
  return locales.includes(value as Locale);
}
