import { notFound } from "next/navigation";
import { isLocale, locales } from "@/lib/i18n";

export function generateStaticParams() { return locales.map((locale) => ({ locale })); }

export default async function LocaleLayout({ children, params }: Readonly<{ children: React.ReactNode; params: Promise<{ locale: string }> }>) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();
  return <><script dangerouslySetInnerHTML={{ __html: `document.documentElement.lang='${locale}';try{var t=localStorage.getItem('nurlyhome-theme');if(t)document.documentElement.dataset.theme=t}catch(e){}` }} />{children}</>;
}
