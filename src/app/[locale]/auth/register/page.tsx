import Link from "next/link";
import { notFound } from "next/navigation";
import { isLocale,dictionaries } from "@/lib/i18n";
import { SiteHeader } from "@/components/site-header";
import { SiteFooter } from "@/components/site-footer";
import { AuthForm } from "@/components/auth-form";
export default async function RegisterPage({params,searchParams}:{params:Promise<{locale:string}>;searchParams:Promise<{error?:string}>}){const {locale:raw}=await params;const query=await searchParams;if(!isLocale(raw))notFound();const locale=raw;const t=dictionaries[locale];return <><SiteHeader locale={locale}/><main className="auth-wrap"><div className="auth-card"><div className="eyebrow">nurlyhome</div><h1>{t.signup}</h1><p>{t.registerSubtitle}</p><AuthForm locale={locale} mode="register" error={query.error}/><p className="muted" style={{textAlign:"center",fontSize:13,marginTop:18}}>{t.authUnavailable}</p><p style={{textAlign:"center",fontSize:13}}>{locale==="ru"?"Уже есть аккаунт?":locale==="kk"?"Аккаунтыңыз бар ма?":"Already have an account?"} <Link className="text-link" href={`/${locale}/auth/login`}>{t.login}</Link></p></div></main><SiteFooter locale={locale}/></>}
